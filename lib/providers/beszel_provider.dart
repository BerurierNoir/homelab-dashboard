import 'dart:async' show Timer, TimeoutException;
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/beszel_stats.dart';
import '../services/http_client_factory.dart';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

// SharedPreferences keys (non-sensitive)
const _kUrl = 'beszel_url';
const _kSystemId = 'beszel_system_id';
const _kSystemName = 'beszel_system_name';
// SecureStorage keys (sensitive)
const _kEmail = 'beszel_email';
const _kPassword = 'beszel_password';
const _kToken = 'beszel_token';

class BeszelConfig {
  final String url;
  final String email;
  final String systemId;
  final String systemName;

  const BeszelConfig({
    required this.url,
    required this.email,
    required this.systemId,
    required this.systemName,
  });
}

class BeszelState {
  final BeszelStats? stats;
  final BeszelConfig? config;
  final bool configured;
  final bool loading;
  final String? lastError;

  const BeszelState({
    this.stats,
    this.config,
    this.configured = false,
    this.loading = false,
    this.lastError,
  });

  BeszelState copyWith({
    BeszelStats? stats,
    BeszelConfig? config,
    bool? configured,
    bool? loading,
    String? lastError,
  }) =>
      BeszelState(
        stats: stats ?? this.stats,
        config: config ?? this.config,
        configured: configured ?? this.configured,
        loading: loading ?? this.loading,
        lastError: lastError ?? this.lastError,
      );
}

class BeszelNotifier extends StateNotifier<BeszelState> {
  BeszelNotifier() : super(const BeszelState()) {
    _init();
  }

  Timer? _timer;
  final http.Client _client = buildTrustingClient();

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(_kUrl);
    final systemId = prefs.getString(_kSystemId);
    final systemName = prefs.getString(_kSystemName) ?? '';
    final email = await _storage.read(key: _kEmail) ?? '';

    if (url != null && systemId != null && url.isNotEmpty) {
      final config = BeszelConfig(
        url: url,
        email: email,
        systemId: systemId,
        systemName: systemName,
      );
      state = state.copyWith(config: config, configured: true);
      await refresh();
      _startPolling();
    }
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
  }

  Future<String?> _getToken(String url, String email) async {
    var token = await _storage.read(key: _kToken);
    if (token != null) return token;
    return _authenticate(url, email);
  }

  Future<String?> _authenticate(String url, String email) async {
    final password = await _storage.read(key: _kPassword);
    if (password == null) return null;

    // Nettoyer l'URL (supprimer le slash final)
    final cleanUrl = url.replaceAll(RegExp(r'/+$'), '');

    // Beszel embeds PocketBase — try all three auth endpoints depending on
    // PocketBase version and whether the account is a user, admin, or superuser.
    final endpoints = [
      '$cleanUrl/api/collections/users/auth-with-password',   // regular user
      '$cleanUrl/api/admins/auth-with-password',               // PocketBase admin < 0.23
      '$cleanUrl/api/collections/_superusers/auth-with-password', // PocketBase >= 0.23
    ];

    for (final endpoint in endpoints) {
      try {
        final res = await _client
            .post(
              Uri.parse(endpoint),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'identity': email, 'password': password}),
            )
            .timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          final token = jsonDecode(res.body)['token'] as String?;
          if (token != null) {
            await _storage.write(key: _kToken, value: token);
            return token;
          }
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> refresh() async {
    final cfg = state.config;
    if (cfg == null) return;

    final token = await _getToken(cfg.url, cfg.email);
    if (token == null) {
      state = state.copyWith(
        stats: const BeszelStats.unavailable(),
        loading: false,
        lastError: 'Auth échouée — vérifier identifiants',
      );
      return;
    }

    final statsUrl =
        '${cfg.url}/api/collections/system_stats/records'
        '?filter=(system%3D%22${cfg.systemId}%22)'
        '&sort=-created&perPage=1';

    try {
      final res = await _client
          .get(Uri.parse(statsUrl), headers: {'Authorization': token})
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 401) {
        await _storage.delete(key: _kToken);
        final newToken = await _authenticate(cfg.url, cfg.email);
        if (newToken == null) {
          state = state.copyWith(
            stats: const BeszelStats.unavailable(),
            loading: false,
            lastError: 'Token expiré — re-auth échouée',
          );
          return;
        }
        final retry = await _client
            .get(Uri.parse(statsUrl), headers: {'Authorization': newToken})
            .timeout(const Duration(seconds: 10));
        _parseStats(retry, cfg.systemName);
        return;
      }

      if (res.statusCode != 200) {
        state = state.copyWith(
          stats: const BeszelStats.unavailable(),
          loading: false,
          lastError: 'HTTP ${res.statusCode}',
        );
        return;
      }

      _parseStats(res, cfg.systemName);
    } on TimeoutException {
      state = state.copyWith(
        stats: const BeszelStats.unavailable(),
        lastError: 'Timeout — ${cfg.url}',
      );
    } catch (e) {
      state = state.copyWith(
        stats: const BeszelStats.unavailable(),
        lastError: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void _parseStats(http.Response res, String systemName) {
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final items = body['items'] as List?;
      if (items != null && items.isNotEmpty) {
        final record = items.first as Map<String, dynamic>;
        // 'stats' can be a Map (PocketBase JSON field) or a JSON-encoded String
        final rawStats = record['stats'];
        final statsJson = rawStats is Map<String, dynamic>
            ? rawStats
            : rawStats is String
                ? jsonDecode(rawStats) as Map<String, dynamic>?
                : null;
        if (statsJson != null) {
          state = BeszelState(
            stats: BeszelStats.fromJson(statsJson, systemName),
            config: state.config,
            configured: state.configured,
            loading: false,
            lastError: null,
          );
          return;
        }
        state = state.copyWith(
          stats: const BeszelStats.unavailable(),
          loading: false,
          lastError: 'Aucune donnée reçue (clé "stats" absente)',
        );
        return;
      }
      state = state.copyWith(
        stats: const BeszelStats.unavailable(),
        loading: false,
        lastError: 'Aucun enregistrement pour ce système',
      );
      return;
    }
    state = state.copyWith(
      stats: const BeszelStats.unavailable(),
      loading: false,
      lastError: 'HTTP ${res.statusCode}',
    );
  }

  // Called from settings to save and activate Beszel config
  Future<bool> configure({
    required String url,
    required String email,
    required String password,
  }) async {
    await _storage.write(key: _kEmail, value: email);
    await _storage.write(key: _kPassword, value: password);
    await _storage.delete(key: _kToken);

    final token = await _authenticate(url, email);
    return token != null;
  }

  Future<List<Map<String, String>>> fetchSystems(String url) async {
    final token = await _storage.read(key: _kToken);
    if (token == null) return [];
    try {
      final res = await _client.get(
        Uri.parse('$url/api/collections/systems/records?perPage=50'),
        headers: {'Authorization': token},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final items = jsonDecode(res.body)['items'] as List;
        return items
            .map((e) => {
                  'id': e['id'] as String,
                  'name': e['name'] as String,
                })
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> selectSystem(
      String url, String systemId, String systemName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUrl, url.replaceAll(RegExp(r'/+$'), ''));
    await prefs.setString(_kSystemId, systemId);
    await prefs.setString(_kSystemName, systemName);

    final email = await _storage.read(key: _kEmail) ?? '';
    final config =
        BeszelConfig(url: url, email: email, systemId: systemId, systemName: systemName);
    state = state.copyWith(config: config, configured: true, loading: true);
    await refresh();
    _startPolling();
  }

  Future<void> clearConfig() async {
    _timer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUrl);
    await prefs.remove(_kSystemId);
    await prefs.remove(_kSystemName);
    await _storage.delete(key: _kEmail);
    await _storage.delete(key: _kPassword);
    await _storage.delete(key: _kToken);
    state = const BeszelState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _client.close();
    super.dispose();
  }
}

final beszelProvider =
    StateNotifierProvider<BeszelNotifier, BeszelState>((_) => BeszelNotifier());
