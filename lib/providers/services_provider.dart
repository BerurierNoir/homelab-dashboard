import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service.dart';

class ServicesState {
  final List<ServiceModel> services;
  final NetworkMode networkMode;
  final bool isLoading;

  const ServicesState({
    required this.services,
    this.networkMode = NetworkMode.local,
    this.isLoading = false,
  });

  ServicesState copyWith({
    List<ServiceModel>? services,
    NetworkMode? networkMode,
    bool? isLoading,
  }) =>
      ServicesState(
        services: services ?? this.services,
        networkMode: networkMode ?? this.networkMode,
        isLoading: isLoading ?? this.isLoading,
      );
}

class ServicesNotifier extends StateNotifier<ServicesState> {
  ServicesNotifier()
      : super(const ServicesState(services: kDefaultServices)) {
    _load();
  }

  static const _prefsKey = 'services_overrides_v2';
  static const _modeKey = 'network_mode';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final modeStr = prefs.getString(_modeKey) ?? 'local';
    final mode =
        modeStr == 'tailscale' ? NetworkMode.tailscale : NetworkMode.local;

    // Start all services at the right URL for the saved mode
    var services = kDefaultServices
        .map((s) => s.copyWith(currentUrl: s.urlForMode(mode)))
        .toList();

    // Apply per-service overrides (enabled flag + custom URLs)
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final Map<String, dynamic> overrides = jsonDecode(raw);
        services = services.map((s) {
          final o = overrides[s.id];
          if (o == null) return s;
          final isCustom = o['isCustomUrl'] as bool? ?? false;
          return s.copyWith(
            enabled: o['enabled'] as bool?,
            currentUrl: isCustom ? (o['url'] as String?) : s.urlForMode(mode),
            isCustomUrl: isCustom,
          );
        }).toList();
      } catch (_) {}
    }

    state = state.copyWith(services: services, networkMode: mode);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _modeKey,
      state.networkMode == NetworkMode.tailscale ? 'tailscale' : 'local',
    );
    final map = <String, dynamic>{};
    for (final s in state.services) {
      map[s.id] = {
        'enabled': s.enabled,
        'url': s.currentUrl,
        'isCustomUrl': s.isCustomUrl,
      };
    }
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  Future<void> setNetworkMode(NetworkMode mode) async {
    final updated = state.services.map((s) {
      if (s.isCustomUrl) return s;
      return s.copyWith(currentUrl: s.urlForMode(mode), isCustomUrl: false);
    }).toList();
    state = state.copyWith(services: updated, networkMode: mode);
    await _save();
  }

  void toggleEnabled(String id) {
    state = state.copyWith(
      services: state.services.map((s) {
        if (s.id != id) return s;
        return s.copyWith(enabled: !s.enabled);
      }).toList(),
    );
    _save();
  }

  void updateUrl(String id, String url) {
    state = state.copyWith(
      services: state.services.map((s) {
        if (s.id != id) return s;
        return s.copyWith(currentUrl: url, isCustomUrl: true);
      }).toList(),
    );
    _save();
  }

  void resetAllUrls() {
    final mode = state.networkMode;
    state = state.copyWith(
      services: state.services
          .map((s) => s.copyWith(
                currentUrl: s.urlForMode(mode),
                isCustomUrl: false,
              ))
          .toList(),
    );
    _save();
  }
}

final servicesProvider =
    StateNotifierProvider<ServicesNotifier, ServicesState>(
        (_) => ServicesNotifier());

final enabledServicesProvider = Provider<List<ServiceModel>>((ref) {
  return ref.watch(servicesProvider).services.where((s) => s.enabled).toList();
});
