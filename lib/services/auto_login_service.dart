import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import '../models/service.dart';
import 'credential_service.dart';

class AutoLoginService {
  Future<void> performLogin({
    required ServiceModel service,
    required WebViewController controller,
    required String currentUrl,
  }) async {
    if (service.autoLoginMethod == AutoLoginMethod.none) return;

    // Ne tenter l'auto-login que si on est sur une page de login
    final isLoginPage = _isLoginPage(currentUrl);
    if (!isLoginPage && service.autoLoginMethod == AutoLoginMethod.jsInjection) return;

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

  bool _isLoginPage(String url) {
    final lower = url.toLowerCase();
    return lower.contains('login') ||
        lower.contains('signin') ||
        lower.contains('auth') ||
        lower.contains('connexion') ||
        lower.contains('sign-in') ||
        lower.contains('log-in') ||
        lower.contains('/ui/#/login') ||    // Proxmox
        lower.contains('/?next=') ||         // Paperless, Mealie
        lower.endsWith('/') ||               // Racine = souvent login si pas auth
        lower.contains('welcome');
  }

  // ── JS Injection — sélecteurs spécifiques par service ─────────────────

  Future<void> _jsInjectionLogin(
      ServiceModel service, WebViewController controller) async {
    final username = await credentialService.getUsername(service.id);
    final password = await credentialService.getPassword(service.id);
    if (username == null || password == null) return;
    if (username.isEmpty || password.isEmpty) return;

    final jsUser = jsonEncode(username);
    final jsPass = jsonEncode(password);

    // Sélecteurs spécifiques selon le service
    final selectors = _getSelectors(service.id);

    await Future.delayed(const Duration(milliseconds: 1800));
    await controller.runJavaScript('''
      (function() {
        try {
          // Sélecteurs spécifiques au service
          var userSel = ${jsonEncode(selectors['user'])};
          var passSel = ${jsonEncode(selectors['pass'])};
          var submitSel = ${jsonEncode(selectors['submit'])};

          function setVal(el, val) {
            var nativeInput = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value');
            if (nativeInput) {
              nativeInput.set.call(el, val);
            } else {
              el.value = val;
            }
            el.dispatchEvent(new Event('input', {bubbles: true}));
            el.dispatchEvent(new Event('change', {bubbles: true}));
          }

          var userField = document.querySelector(userSel);
          var passField = document.querySelector(passSel);

          if (!userField || !passField) {
            // Fallback générique
            userField = document.querySelector(
              'input[type="text"], input[name="username"], input[id*="user"], input[autocomplete="username"], input[name="email"]'
            );
            passField = document.querySelector('input[type="password"]');
          }

          if (userField && passField) {
            setVal(userField, $jsUser);
            setVal(passField, $jsPass);

            setTimeout(function() {
              var btn = document.querySelector(submitSel);
              if (!btn) {
                btn = document.querySelector(
                  'button[type="submit"], input[type="submit"], button.login, button.signin, button.btn-primary'
                );
              }
              if (btn) {
                btn.click();
              } else {
                var form = passField.closest('form');
                if (form) form.dispatchEvent(new Event('submit', {bubbles: true}));
              }
            }, 300);
          }
        } catch(e) {
          console.log('AutoLogin error:', e);
        }
      })();
    ''');
  }

  /// Sélecteurs CSS par service pour cibler précisément les formulaires
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
          'user': 'input[id="username"], input[name="username"]',
          'pass': 'input[type="password"]',
          'submit': 'button[type="submit"]',
        };
      case 'paperless':
        return {
          'user': 'input[name="username"], input[id="id_username"]',
          'pass': 'input[name="password"], input[id="id_password"]',
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
          'user': 'input[placeholder*="username" i], input[id="username"]',
          'pass': 'input[type="password"]',
          'submit': 'button[type="submit"]',
        };
      case 'beszel':
        return {
          'user': 'input[name="identity"], input[autocomplete="email"]',
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
      case 'homepage':
      case 'jotty':
      case 'vaultwarden':
        return {
          'user': 'input[type="email"], input[name="email"]',
          'pass': 'input[type="password"]',
          'submit': 'button[type="submit"]',
        };
      default:
        return {
          'user': 'input[type="text"], input[name="username"], input[autocomplete="username"]',
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
      );
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
              'localStorage.setItem("jellyfin_credentials", $jsCredentials);');
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
