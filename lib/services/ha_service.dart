import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/ha_entity.dart';

class HaService {
  final String baseUrl;
  final String token;

  HaService({required this.baseUrl, required this.token});

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  String get _wsUrl {
    final uri = Uri.parse(baseUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    // Nabu Casa : port 443 standard, ne pas l'ajouter explicitement
    final port = (uri.port == 443 || uri.port == 80 || uri.port == -1) 
        ? '' : ':${uri.port}';
    return '$scheme://${uri.host}$port/api/websocket';
  }

  // ── REST ──────────────────────────────────────────────────

  Future<String?> testConnectionDetailed() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/'), headers: _headers)
          .timeout(const Duration(seconds: 8));
      
      if (res.statusCode == 200) {
        final body = res.body;
        if (body.contains('message') || body.contains('API')) {
          return null; // OK
        }
        if (body.trimLeft().startsWith('<')) {
          return 'Réponse HTML reçue — token invalide ou URL incorrecte';
        }
        return null; // OK
      } else if (res.statusCode == 401) {
        return 'Token invalide (401)';
      } else if (res.statusCode == 403) {
        return 'Accès refusé (403)';
      } else {
        return 'Erreur HTTP ${res.statusCode}';
      }
    } on TimeoutException {
      return 'Timeout — HA inaccessible';
    } catch (e) {
      return e.toString();
    }
  }

  Future<bool> testConnection() async {
    return (await testConnectionDetailed()) == null;
  }

  Future<Map<String, HaEntity>> getStates(List<String> entityIds) async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/states'), headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 401) {
      throw Exception('Token invalide ou expiré. Vérifiez votre token dans les settings.');
    }
    if (res.statusCode != 200) throw Exception('HA API error: ${res.statusCode}');
    // Détecter si on reçoit du HTML au lieu de JSON (URL mal configurée)
    final body = res.body;
    if (body.trimLeft().startsWith('<!') || body.trimLeft().startsWith('<html')) {
      throw Exception(
        "L'URL retourne une page HTML.\n"
        "Vérifiez votre URL dans les settings.\n"
        "Nabu Casa : https://XXXXX.ui.nabu.casa\n"
        "Local : http://192.168.1.X:8123"
      );
    }

    final List<dynamic> all = jsonDecode(body);
    final result = <String, HaEntity>{};
    for (final item in all) {
      final entity = HaEntity.fromJson(item as Map<String, dynamic>);
      if (entityIds.contains(entity.entityId)) {
        result[entity.entityId] = entity;
      }
    }
    return result;
  }

  Future<void> callService({
    required String domain,
    required String service,
    required String entityId,
    Map<String, dynamic>? extraData,
  }) async {
    final body = jsonEncode({
      'entity_id': entityId,
      ...?extraData,
    });
    await http
        .post(
          Uri.parse('$baseUrl/api/services/$domain/$service'),
          headers: _headers,
          body: body,
        )
        .timeout(const Duration(seconds: 8));
  }

  /// Appel intelligent selon le domaine de l'entité
  Future<void> smartCall(String entityId) async {
    final domain = entityId.split('.').first;
    final String service;
    switch (domain) {
      case 'script':
        service = 'turn_on';
        break;
      case 'scene':
        service = 'turn_on';
        break;
      case 'automation':
        service = 'trigger';
        break;
      case 'button':
        service = 'press';
        break;
      case 'input_button':
        service = 'press';
        break;
      case 'cover':
      case 'switch':
      case 'light':
      case 'fan':
      case 'input_boolean':
      case 'media_player':
      default:
        service = 'toggle';
    }
    await callService(domain: domain, service: service, entityId: entityId);
  }

  /// Appel d'un webhook HA (pas d'auth requise)
  Future<void> callWebhook(String webhookId) async {
    await http.post(
      Uri.parse('${baseUrl}/api/webhook/${webhookId}'),
      headers: {'Content-Type': 'application/json'},
      body: '{}',
    ).timeout(const Duration(seconds: 8));
  }

  Future<void> toggle(String entityId) async {
    await smartCall(entityId);
  }

  Future<void> turnOn(String entityId) async {
    final domain = entityId.split('.').first;
    await callService(domain: domain, service: 'turn_on', entityId: entityId);
  }

  Future<void> turnOff(String entityId) async {
    final domain = entityId.split('.').first;
    await callService(domain: domain, service: 'turn_off', entityId: entityId);
  }

  // ── WebSocket temps réel ───────────────────────────────────

  Stream<Map<String, dynamic>> connectWebSocket() {
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    WebSocketChannel? channel;
    int msgId = 1;

    void connect() {
      try {
        channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
        channel!.stream.listen(
          (data) {
            final msg = jsonDecode(data as String) as Map<String, dynamic>;
            final type = msg['type'] as String?;

            if (type == 'auth_required') {
              channel!.sink.add(jsonEncode({
                'type': 'auth',
                'access_token': token,
              }));
            } else if (type == 'auth_ok') {
              // S'abonner aux changements d'état
              channel!.sink.add(jsonEncode({
                'id': msgId++,
                'type': 'subscribe_events',
                'event_type': 'state_changed',
              }));
            } else if (type == 'event') {
              final event = msg['event'] as Map<String, dynamic>?;
              final eventData = event?['data'] as Map<String, dynamic>?;
              if (eventData != null) {
                controller.add(eventData);
              }
            }
          },
          onError: (e) {
            // Reconnexion automatique après 5s
            Future.delayed(const Duration(seconds: 5), connect);
          },
          onDone: () {
            Future.delayed(const Duration(seconds: 5), connect);
          },
        );
      } catch (_) {
        Future.delayed(const Duration(seconds: 5), connect);
      }
    }

    connect();
    return controller.stream;
  }
}
