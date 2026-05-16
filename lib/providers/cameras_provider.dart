import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/camera_config.dart';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

String _urlKey(String id) => 'camera_${id}_url';
const _configsKey = 'cameras_v1';

class CamerasNotifier extends StateNotifier<List<CameraConfig>> {
  CamerasNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_configsKey);
    if (raw != null) {
      state = CameraConfig.listFromJson(raw);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configsKey, CameraConfig.listToJson(state));
  }

  Future<void> addCamera(CameraConfig config, String streamUrl) async {
    await _storage.write(key: _urlKey(config.id), value: streamUrl);
    state = [...state, config];
    await _save();
  }

  Future<void> updateCamera(
      CameraConfig config, String? streamUrl) async {
    if (streamUrl != null) {
      await _storage.write(key: _urlKey(config.id), value: streamUrl);
    }
    state = [
      for (final c in state) c.id == config.id ? config : c,
    ];
    await _save();
  }

  Future<void> removeCamera(String id) async {
    await _storage.delete(key: _urlKey(id));
    state = state.where((c) => c.id != id).toList();
    await _save();
  }

  Future<String?> getStreamUrl(String id) =>
      _storage.read(key: _urlKey(id));
}

final camerasProvider =
    StateNotifierProvider<CamerasNotifier, List<CameraConfig>>(
        (_) => CamerasNotifier());

final enabledCamerasProvider = Provider<List<CameraConfig>>((ref) {
  return ref.watch(camerasProvider).where((c) => c.enabled).toList();
});
