import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LockType { none, biometric }

class AppSettings {
  final bool isDarkTheme;
  final int refreshIntervalSeconds;
  final LockType lockType;
  final String? wallpaperPath;
  final bool loaded;

  const AppSettings({
    this.isDarkTheme = true,
    this.refreshIntervalSeconds = 60,
    this.lockType = LockType.none,
    this.wallpaperPath,
    this.loaded = false,
  });

  AppSettings copyWith({
    bool? isDarkTheme,
    int? refreshIntervalSeconds,
    LockType? lockType,
    String? wallpaperPath,
    bool clearWallpaper = false,
    bool? loaded,
  }) =>
      AppSettings(
        isDarkTheme: isDarkTheme ?? this.isDarkTheme,
        refreshIntervalSeconds:
            refreshIntervalSeconds ?? this.refreshIntervalSeconds,
        lockType: lockType ?? this.lockType,
        wallpaperPath:
            clearWallpaper ? null : (wallpaperPath ?? this.wallpaperPath),
        loaded: loaded ?? this.loaded,
      );
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final lockStr = p.getString('lock_type') ?? 'none';
    // Migrate old 'pin' setting to 'biometric' (uses Android system auth now)
    final lockType = lockStr == 'pin'
        ? LockType.biometric
        : LockType.values.firstWhere((e) => e.name == lockStr,
            orElse: () => LockType.none);
    state = AppSettings(
      isDarkTheme: p.getBool('dark_theme') ?? true,
      refreshIntervalSeconds: p.getInt('refresh_interval') ?? 60,
      lockType: lockType,
      wallpaperPath: p.getString('wallpaper_path'),
      loaded: true,
    );
  }

  Future<void> setDarkTheme(bool v) async {
    state = state.copyWith(isDarkTheme: v);
    final p = await SharedPreferences.getInstance();
    await p.setBool('dark_theme', v);
  }

  Future<void> setRefreshInterval(int seconds) async {
    state = state.copyWith(refreshIntervalSeconds: seconds);
    final p = await SharedPreferences.getInstance();
    await p.setInt('refresh_interval', seconds);
  }

  Future<void> setLockType(LockType type) async {
    state = state.copyWith(lockType: type);
    final p = await SharedPreferences.getInstance();
    await p.setString('lock_type', type.name);
  }

  Future<void> setWallpaper(String path) async {
    state = state.copyWith(wallpaperPath: path);
    final p = await SharedPreferences.getInstance();
    await p.setString('wallpaper_path', path);
  }

  Future<void> clearWallpaper() async {
    state = state.copyWith(clearWallpaper: true);
    final p = await SharedPreferences.getInstance();
    await p.remove('wallpaper_path');
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>(
        (_) => SettingsNotifier());
