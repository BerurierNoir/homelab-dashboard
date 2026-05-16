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
      };

  String get _wsUrl {
    final uri = Uri.parse(baseUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return '$scheme://${uri.host}:${uri.port}/api/websocket';
  }

  // ── REST ──────────────────────────────────────────────────

  Future<bool> testConnection() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/'), headers: _headers)
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, HaEntity>> getStates(List<String> entityIds) async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/states'), headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) throw Exception('HA API error: ${res.statusCode}');

    final List<dynamic> all = jsonDecode(res.body);
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

  Future<void> toggle(String entityId) async {
    final domain = entityId.split('.').first;
    final svc = domain == 'cover' ? 'toggle' : 'toggle';
    await callService(domain: domain, service: svc, entityId: entityId);
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
