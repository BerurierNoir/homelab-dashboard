import '../utils/url_utils.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service.dart';

class ServicesState {
  final List<ServiceModel> services;
  final bool isLoading;

  const ServicesState({
    required this.services,
    this.isLoading = false,
  });

  ServicesState copyWith({
    List<ServiceModel>? services,
    bool? isLoading,
  }) =>
      ServicesState(
        services: services ?? this.services,
        isLoading: isLoading ?? this.isLoading,
      );
}

class ServicesNotifier extends StateNotifier<ServicesState> {
  ServicesNotifier()
      : super(const ServicesState(services: kDefaultServices)) {
    _load();
  }

  static const _prefsKey = 'services_overrides_v3';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    var services = List<ServiceModel>.from(kDefaultServices);

    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final Map<String, dynamic> overrides = jsonDecode(raw);
        services = services.map((s) {
          final o = overrides[s.id];
          if (o == null) return s;
          return s.copyWith(
            enabled: o['enabled'] as bool?,
            url: o['url'] as String?,
          );
        }).toList();
      } catch (_) {}
    }

    state = state.copyWith(services: services);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, dynamic>{};
    for (final s in state.services) {
      map[s.id] = {
        'enabled': s.enabled,
        'url': s.url,
      };
    }
    await prefs.setString(_prefsKey, jsonEncode(map));
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

  void updateUrl(String id, String rawUrl) {
    final url = rawUrl.isEmpty ? rawUrl : cleanUrl(rawUrl);
    state = state.copyWith(
      services: state.services.map((s) {
        if (s.id != id) return s;
        return s.copyWith(url: url);
      }).toList(),
    );
    _save();
  }

  void resetUrl(String id) {
    state = state.copyWith(
      services: state.services.map((s) {
        if (s.id != id) return s;
        return s.copyWith(url: s.defaultUrl);
      }).toList(),
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
