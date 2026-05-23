import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import '../models/service.dart';
import 'credential_service.dart';

class AutoLoginService {
  // JS qui détecte ET remplit le formulaire — appelé sur chaque page
  // La détection se fait côté JS (cherche input[type=password])
  // pas côté Dart (URL) pour éviter les faux négatifs
  Future<void> performLogin({
    required ServiceModel service,
    required WebViewController controller,
    required String currentUrl,
  }) async {
    if (service.autoLoginMethod == AutoLoginMethod.none) return;

    switch (service.autoLoginMethod) {
      case AutoLoginMethod.jsInjection:
        await _jsInjectionLogin(service, controller);
        break;
      case AutoLoginMethod.apiToken:
        await _apiTokenLogin(service, controller, currentUrl);
        break;
      case AutoLoginMethod.none:
        break;
    }
  }

  // ── JS Injection ───────────────────────────────────────────────────────

  Future<void> _jsInjectionLogin(
      ServiceModel service, WebViewController controller) async {
    final username = await credentialService.getUsername(service.id);
    final password = await credentialService.getPassword(service.id);
    if (username == null || password == null) return;
    if (username.isEmpty || password.isEmpty) return;

    final jsUser = jsonEncode(username);
    final jsPass = jsonEncode(password);
    final selectors = _getSelectors(service.id);

    // Tenter plusieurs fois avec délais croissants
    for (final delay in [1200, 2500, 4000]) {
      await Future.delayed(Duration(milliseconds: delay));
      final result = await controller.runJavaScriptReturningResult('''
        (function() {
          // Vérifier qu'il y a un champ password (= page de login)
          var passField = document.querySelector(${jsonEncode(selectors['pass'])}) ||
                          document.querySelector('input[type="password"]');
          if (!passField) return 'no_password_field';
          
          function setNativeVal(el, val) {
            var proto = Object.getOwnPropertyDescriptor(
              window.HTMLInputElement.prototype, 'value');
            if (proto && proto.set) {
              proto.set.call(el, val);
            } else {
              el.value = val;
            }
            ['input','change','keyup','keydown'].forEach(function(e) {
              el.dispatchEvent(new Event(e, {bubbles: true}));
            });
          }

          var userField = document.querySelector(${jsonEncode(selectors['user'])}) ||
              document.querySelector([
                'input[name="username"]',
                'input[name="email"]',
                'input[type="email"]',
                'input[type="text"]',
                'input[autocomplete="username"]',
                'input[autocomplete="email"]',
                'input[id*="user"]',
                'input[id*="login"]',
                'input[id*="email"]'
              ].join(','));

          if (!userField) return 'no_user_field';

          setNativeVal(userField, $jsUser);
          setNativeVal(passField, $jsPass);

          // Focus sur passField puis simule Enter
          passField.focus();

          // Chercher le bouton submit
          var btn = document.querySelector(${jsonEncode(selectors['submit'])}) ||
              document.querySelector([
                'button[type="submit"]',
                'input[type="submit"]',
                'button.login-button',
                'button.btn-primary',
                'button.btn-login',
                'button[class*="submit"]',
                'button[class*="login"]',
                'button[class*="sign"]',
                '[role="button"][class*="submit"]',
                '[role="button"][class*="login"]'
              ].join(','));

          if (btn) {
            setTimeout(function() { btn.click(); }, 300);
            return 'clicked_button';
          }

          // Fallback: submit le form ou Enter
          var form = passField.closest('form');
          if (form) {
            setTimeout(function() {
              form.dispatchEvent(new Event('submit', {bubbles: true, cancelable: true}));
            }, 300);
            return 'submitted_form';
          }

          // Dernier recours: KeyboardEvent Enter
          setTimeout(function() {
            passField.dispatchEvent(new KeyboardEvent('keydown', {
              key: 'Enter', code: 'Enter', keyCode: 13,
              which: 13, bubbles: true
            }));
          }, 300);
          return 'pressed_enter';
        })();
      ''');

      // Si on a trouvé et rempli → arrêter les retries
      final res = result.toString().replaceAll('"', '');
      if (res != 'no_password_field' && res != 'no_user_field') break;
    }
  }

  /// Sélecteurs CSS spécifiques par service
  Map<String, String> _getSelectors(String serviceId) {
    switch (serviceId) {
      case 'proxmox':
        return {
          'user': 'input[name="username"]',
          'pass': 'input[name="password"]',
          'submit': 'button[type="submit"]',
        };
      case 'mealie':
        return {
          'user': 'input[id="username"]',
          'pass': 'input[type="password"]',
          'submit': 'button[type="submit"]',
        };
      case 'paperless':
        return {
          'user': 'input[id="id_username"], input[name="username"]',
          'pass': 'input[id="id_password"], input[name="password"]',
          'submit': 'input[type="submit"], button[type="submit"]',
        };
      case 'kavita':
        return {
          'user': 'input[id="username"]',
          'pass': 'input[id="password"]',
          'submit': 'button[type="submit"]',
        };
      case 'immich':
        return {
          'user': 'input[id="email"], input[type="email"]',
          'pass': 'input[id="password"]',
          'submit': 'button[type="submit"]',
        };
      case 'uptimekuma':
        return {
          'user': 'input[id="username"]',
          'pass': 'input[type="password"]',
          'submit': 'button[type="submit"]',
        };
      case 'beszel':
        return {
          'user': 'input[name="identity"]',
          'pass': 'input[name="password"]',
          'submit': 'button[type="submit"]',
        };
      case 'portainer':
        return {
          'user': 'input[name="username"]',
          'pass': 'input[name="password"]',
          'submit': 'button[type="submit"]',
        };
      case 'grafana':
        return {
          'user': 'input[name="user"]',
          'pass': 'input[name="password"]',
          'submit': 'button[aria-label="Login button"]',
        };
      case 'vaultwarden':
        return {
          'user': 'input[type="email"]',
          'pass': 'input[type="password"]',
          'submit': 'button[type="submit"]',
        };
      default:
        return {
          'user': 'input[type="text"]',
          'pass': 'input[type="password"]',
          'submit': 'button[type="submit"]',
        };
    }
  }

  // ── API Token / Jellyfin / HA ──────────────────────────────────────────

  Future<void> _apiTokenLogin(
      ServiceModel service,
      WebViewController controller,
      String currentUrl) async {
    if (service.id == 'jellyfin') {
      await _jellyfinLogin(service, controller);
    } else if (service.id == 'homeassistant') {
      await _homeAssistantLogin(service, controller);
    }
  }

  Future<void> _jellyfinLogin(
      ServiceModel service, WebViewController controller) async {
    final username = await credentialService.getUsername(service.id);
    final password = await credentialService.getPassword(service.id);
    if (username == null || password == null) return;
    if (username.isEmpty || password.isEmpty) return;

    try {
      final uri = Uri.parse('${service.url}/Users/AuthenticateByName');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-Emby-Authorization':
              'MediaBrowser Client="HomeLab", Device="Android", DeviceId="homelab-dash", Version="1.0"',
        },
        body: jsonEncode({'Username': username, 'Pw': password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['AccessToken'] as String?;
        if (token != null) {
          await credentialService.saveToken(service.id, token);
          final jsCredentials = jsonEncode({
            'Servers': [
              {'AccessToken': token, 'UserId': data['User']['Id']}
            ]
          });
          await controller.runJavaScript(
              'localStorage.setItem("jellyfin_credentials", $jsCredentials);'
              'window.location.reload();');
        }
      }
    } catch (_) {}
  }

  Future<void> _homeAssistantLogin(
      ServiceModel service, WebViewController controller) async {
    final token = await credentialService.getToken(service.id);
    if (token == null || token.isEmpty) return;

    await Future.delayed(const Duration(milliseconds: 2000));
    final jsToken = jsonEncode(token);
    await controller.runJavaScript('''
      (function() {
        try {
          var hassData = JSON.parse(localStorage.getItem('hassTokens') || '{}');
          hassData.access_token = $jsToken;
          hassData.token_type = 'Bearer';
          localStorage.setItem('hassTokens', JSON.stringify(hassData));
        } catch(e) {}
      })();
    ''');
    await controller.reload();
  }
}

final autoLoginService = AutoLoginService();
