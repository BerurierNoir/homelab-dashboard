import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/ha_entity.dart';
import '../services/ha_service.dart';

// ── Config ────────────────────────────────────────────────────

class HaConfig {
  final String url;
  final String token;

  const HaConfig({required this.url, required this.token});

  bool get isConfigured => url.isNotEmpty && token.isNotEmpty;
}

class HaConfigNotifier extends Notifier<HaConfig> {
  static const _urlKey = 'ha_url';
  static const _tokenKey = 'ha_token';

  @override
  HaConfig build() {
    _load();
    return const HaConfig(url: '', token: '');
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    // Token depuis secure storage, fallback prefs pour compat ancienne version
    const sec = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    final token = await sec.read(key: _tokenKey) ??
        prefs.getString(_tokenKey) ?? '';
    state = HaConfig(
      url: prefs.getString(_urlKey) ?? '',
      token: token,
    );
  }

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> save({required String url, required String token}) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanUrl = url.trimRight().replaceAll(RegExp(r'/$'), '');
    await prefs.setString(_urlKey, cleanUrl);
    // Token stocké en secure storage (chiffré)
    await _secureStorage.write(key: _tokenKey, value: token.trim());
    state = HaConfig(url: cleanUrl, token: token.trim());
  }
}

final haConfigProvider = NotifierProvider<HaConfigNotifier, HaConfig>(
  HaConfigNotifier.new,
);

// ── État global HA ────────────────────────────────────────────

class HaState {
  final Map<String, HaEntity> entities;
  final bool isLoading;
  final bool isConnected;
  final String? error;

  const HaState({
    this.entities = const {},
    this.isLoading = false,
    this.isConnected = false,
    this.error,
  });

  HaEntity? entity(String id) => entities[id];

  HaState copyWith({
    Map<String, HaEntity>? entities,
    bool? isLoading,
    bool? isConnected,
    String? error,
  }) {
    return HaState(
      entities: entities ?? this.entities,
      isLoading: isLoading ?? this.isLoading,
      isConnected: isConnected ?? this.isConnected,
      error: error,
    );
  }
}

class HaNotifier extends Notifier<HaState> {
  HaService? _service;
  StreamSubscription<Map<String, dynamic>>? _wsSub;
  Timer? _refreshTimer;

  @override
  HaState build() {
    ref.listen<HaConfig>(haConfigProvider, (_, config) {
      if (config.isConfigured) _init(config);
    });
    final config = ref.read(haConfigProvider);
    if (config.isConfigured) {
      Future.microtask(() => _init(config));
    }
    ref.onDispose(() {
      _wsSub?.cancel();
      _refreshTimer?.cancel();
    });
    return const HaState(isLoading: true);
  }

  Future<void> _init(HaConfig config) async {
    _wsSub?.cancel();
    _refreshTimer?.cancel();
    _service = HaService(baseUrl: config.url, token: config.token);
    state = state.copyWith(isLoading: true, error: null);
    await _fetchAll();
    _subscribeWs();
    // Rafraîchissement périodique toutes les 30s (backup WebSocket)
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchAll());
  }

  Future<void> _fetchAll() async {
    if (_service == null) return;
    try {
      final entities = await _service!.getStates(HaEntities.allEntities);
      state = state.copyWith(
        entities: entities,
        isLoading: false,
        isConnected: true,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isConnected: false,
        error: e.toString(),
      );
    }
  }

  void _subscribeWs() {
    if (_service == null) return;
    _wsSub = _service!.connectWebSocket().listen((event) {
      final entityId = event['entity_id'] as String?;
      final newState = event['new_state'];
      if (entityId == null || newState == null) return;
      if (!HaEntities.allEntities.contains(entityId)) return;

      final entity = HaEntity.fromJson(newState as Map<String, dynamic>);
      final updated = Map<String, HaEntity>.from(state.entities);
      updated[entityId] = entity;
      state = state.copyWith(entities: updated, isConnected: true);
    });
  }

  Future<void> toggle(String entityId) async {
    if (_service == null) return;
    final domain = entityId.split('.').first;
    // Optimistic update (sauf script/scene/automation/webhook)
    final noOptimistic = ['script', 'scene', 'automation', 'button'];
    if (!noOptimistic.contains(domain)) {
      final current = state.entities[entityId];
      if (current != null) {
        final newState = current.isOn ? 'off' : 'on';
        final updated = Map<String, HaEntity>.from(state.entities);
        updated[entityId] = current.copyWith(state: newState);
        state = state.copyWith(entities: updated);
      }
    }
    try {
      await _service!.smartCall(entityId);
    } catch (_) {
      await _fetchAll();
    }
  }

  Future<void> callService(String domain, String service, String entityId) async {
    if (_service == null) return;
    try {
      await _service!.callService(
        domain: domain,
        service: service,
        entityId: entityId,
      );
    } catch (_) {}
  }

  Future<void> callWebhook(String webhookId) async {
    if (_service == null) return;
    try {
      await _service!.callWebhook(webhookId);
    } catch (_) {}
  }

  Future<void> refresh() => _fetchAll();
}

final haProvider = NotifierProvider<HaNotifier, HaState>(HaNotifier.new);
