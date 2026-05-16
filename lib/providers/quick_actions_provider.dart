import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quick_action.dart';

const _kActions = 'quick_actions_v1';
const _kAuthPrefix = 'qa_auth_';

const _secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

class QuickActionsNotifier extends StateNotifier<List<QuickAction>> {
  QuickActionsNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kActions);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => QuickAction.fromJson(e as Map<String, dynamic>))
          .toList();
      state = list;
    } catch (_) {}
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kActions,
      jsonEncode(state.map((a) => a.toJson()).toList()),
    );
  }

  Future<void> addAction(QuickAction action, {String? authorization}) async {
    state = [...state, action];
    await _persist();
    if (authorization != null && authorization.isNotEmpty) {
      await _secureStorage.write(
          key: '$_kAuthPrefix${action.id}', value: authorization);
    }
  }

  Future<void> updateAction(QuickAction action,
      {String? authorization}) async {
    state = [for (final a in state) a.id == action.id ? action : a];
    await _persist();
    if (authorization != null) {
      if (authorization.isEmpty) {
        await _secureStorage.delete(key: '$_kAuthPrefix${action.id}');
      } else {
        await _secureStorage.write(
            key: '$_kAuthPrefix${action.id}', value: authorization);
      }
    }
  }

  Future<void> removeAction(String id) async {
    state = state.where((a) => a.id != id).toList();
    await _persist();
    await _secureStorage.delete(key: '$_kAuthPrefix$id');
  }

  Future<void> toggleEnabled(String id) async {
    state = [
      for (final a in state)
        a.id == id ? a.copyWith(enabled: !a.enabled) : a,
    ];
    await _persist();
  }

  Future<String?> getAuthorization(String id) =>
      _secureStorage.read(key: '$_kAuthPrefix$id');
}

final quickActionsProvider =
    StateNotifierProvider<QuickActionsNotifier, List<QuickAction>>(
        (_) => QuickActionsNotifier());

final enabledQuickActionsProvider = Provider<List<QuickAction>>(
    (ref) => ref.watch(quickActionsProvider).where((a) => a.enabled).toList());
