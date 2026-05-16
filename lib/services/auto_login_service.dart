import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import '../models/service.dart';
import 'credential_service.dart';

class AutoLoginService {
  Future<void> performLogin({
    required ServiceModel service,
    required WebViewController controller,
  }) async {
    switch (service.autoLoginMethod) {
      case AutoLoginMethod.jsInjection:
        await _jsInjectionLogin(service, controller);
        break;
      case AutoLoginMethod.apiToken:
        await _apiTokenLogin(service, controller);
        break;
      case AutoLoginMethod.none:
        break;
    }
  }

  // ── JS Injection ────────────────────────────────────────────────────────

  Future<void> _jsInjectionLogin(
      ServiceModel service, WebViewController controller) async {
    final username = await credentialService.getUsername(service.id);
    final password = await credentialService.getPassword(service.id);
    if (username == null || password == null) return;

    // jsonEncode produces a properly-escaped JS string literal (handles
    // quotes, backslashes, newlines and other special chars safely).
    final jsUser = jsonEncode(username);
    final jsPass = jsonEncode(password);

    await Future.delayed(const Duration(milliseconds: 1500));
    await controller.runJavaScript('''
      (function() {
        var userField = document.querySelector(
          'input[type="text"], input[name="username"], input[id*="user"], input[id*="login"], input[autocomplete="username"]'
        );
        var passField = document.querySelector('input[type="password"]');
        var submitBtn = document.querySelector(
          'button[type="submit"], input[type="submit"], button.login, button.signin'
        );
        if (userField && passField) {
          userField.value = $jsUser;
          passField.value = $jsPass;
          userField.dispatchEvent(new Event('input', {bubbles: true}));
          userField.dispatchEvent(new Event('change', {bubbles: true}));
          passField.dispatchEvent(new Event('input', {bubbles: true}));
          passField.dispatchEvent(new Event('change', {bubbles: true}));
          if (submitBtn) { submitBtn.click(); }
          else {
            var form = passField.closest('form');
            if (form) form.submit();
          }
        }
      })();
    ''');
  }

  // ── API Token / Jellyfin ────────────────────────────────────────────────

  Future<void> _apiTokenLogin(
      ServiceModel service, WebViewController controller) async {
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

    try {
      final uri = Uri.parse('${service.currentUrl}/Users/AuthenticateByName');
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
    if (token == null) return;

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
