import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/service.dart';
import 'http_client_factory.dart';
class HealthCheckService {
  static const _timeout = Duration(seconds: 8);
  static const _timeoutLong = Duration(seconds: 10);

  final http.Client _client = buildTrustingClient();

  void close() => _client.close();

  Future<ServiceStatus> check(ServiceModel service) async {
    if (service.id == 'klipper') {
      return _checkKlipper(service);
    }
    return _checkGeneric(service);
  }

  Future<ServiceStatus> _checkGeneric(ServiceModel service) async {
    final timeout =
        service.id == 'homeassistant' ? _timeoutLong : _timeout;
    final start = DateTime.now();
    try {
      final uri = Uri.parse(service.currentUrl);
      final response = await _client.get(uri).timeout(timeout);
      final ms = DateTime.now().difference(start).inMilliseconds;
      final isUp = response.statusCode >= 200 && response.statusCode < 500;
      return ServiceStatus(
        serviceId: service.id,
        isUp: isUp,
        responseTimeMs: ms,
        lastChecked: DateTime.now(),
      );
    } on TimeoutException {
      return ServiceStatus(
        serviceId: service.id,
        isUp: false,
        lastChecked: DateTime.now(),
        errorMessage: 'Timeout',
      );
    } catch (e) {
      return ServiceStatus(
        serviceId: service.id,
        isUp: false,
        lastChecked: DateTime.now(),
        errorMessage: e.toString(),
      );
    }
  }

  // Klipper/Moonraker: check status and detect active print job
  Future<ServiceStatus> _checkKlipper(ServiceModel service) async {
    final start = DateTime.now();
    bool isPrinting = false;

    try {
      final baseUrl = service.currentUrl.replaceAll(RegExp(r'/$'), '');
      final uri = Uri.parse('$baseUrl/printer/objects/query?print_stats');
      final response = await _client.get(uri).timeout(_timeout);
      final ms = DateTime.now().difference(start).inMilliseconds;

      if (response.statusCode >= 200 && response.statusCode < 500) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final result = data['result'] as Map<String, dynamic>?;
          final status = result?['status'] as Map<String, dynamic>?;
          final printStats = status?['print_stats'] as Map<String, dynamic>?;
          final state = printStats?['state'] as String?;
          isPrinting = state == 'printing';
        } catch (_) {}

        return ServiceStatus(
          serviceId: service.id,
          isUp: true,
          responseTimeMs: ms,
          lastChecked: DateTime.now(),
          isPrinting: isPrinting,
        );
      }

      return ServiceStatus(
        serviceId: service.id,
        isUp: false,
        responseTimeMs: ms,
        lastChecked: DateTime.now(),
      );
    } on TimeoutException {
      return ServiceStatus(
        serviceId: service.id,
        isUp: false,
        lastChecked: DateTime.now(),
        errorMessage: 'Timeout',
      );
    } catch (e) {
      return ServiceStatus(
        serviceId: service.id,
        isUp: false,
        lastChecked: DateTime.now(),
        errorMessage: e.toString(),
      );
    }
  }

}
