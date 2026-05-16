import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shortcut.dart';

class ShortcutsState {
  final List<AppShortcut> shortcuts;
  const ShortcutsState({required this.shortcuts});
  ShortcutsState copyWith({List<AppShortcut>? shortcuts}) =>
      ShortcutsState(shortcuts: shortcuts ?? this.shortcuts);
}

class ShortcutsNotifier extends StateNotifier<ShortcutsState> {
  ShortcutsNotifier()
      : super(const ShortcutsState(shortcuts: kDefaultShortcuts)) {
    _load();
  }

  static const _prefsKey = 'shortcuts_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final Map<String, dynamic> overrides = jsonDecode(raw);
      final updated = kDefaultShortcuts.map((s) {
        final o = overrides[s.id];
        if (o == null) return s;
        return s.copyWith(enabled: o['enabled'] as bool? ?? false);
      }).toList();
      state = state.copyWith(shortcuts: updated);
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, dynamic>{};
    for (final s in state.shortcuts) {
      map[s.id] = {'enabled': s.enabled};
    }
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  void toggleEnabled(String id) {
    state = state.copyWith(
      shortcuts: state.shortcuts.map((s) {
        if (s.id != id) return s;
        return s.copyWith(enabled: !s.enabled);
      }).toList(),
    );
    _save();
  }
}

final shortcutsProvider =
    StateNotifierProvider<ShortcutsNotifier, ShortcutsState>(
        (_) => ShortcutsNotifier());

final enabledShortcutsProvider = Provider<List<AppShortcut>>((ref) =>
    ref.watch(shortcutsProvider).shortcuts.where((s) => s.enabled).toList());
