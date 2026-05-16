import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

class BackupService {
  static const _kVersion = 1;

  // All SharedPreferences keys to include in the backup
  static const _prefKeys = [
    'services_overrides_v2',
    'network_mode',
    'cameras_v1',
    'shortcuts_v1',
    'quick_actions_v1',
    'beszel_url',
    'beszel_system_id',
    'beszel_system_name',
    'ha_url',
    'dark_theme',
    'refresh_interval',
    'lock_type',
    // wallpaper_path excluded — it's a local file path
  ];

  // beszel_token excluded — it's re-fetched automatically on next auth
  static bool _includeSecureKey(String key) =>
      key.startsWith('cred_') ||
      key.startsWith('camera_') ||
      key.startsWith('qa_auth_') ||
      key == 'beszel_email' ||
      key == 'beszel_password' ||
      key == 'ha_token';

  // Simple iterated SHA-256 KDF: fast enough on mobile, harder to brute-force
  // than a single hash. Not PBKDF2 but adequate for home-lab use.
  static Uint8List _deriveKey(String passphrase, List<int> salt) {
    List<int> bytes = [...utf8.encode(passphrase), ...salt];
    for (int i = 0; i < 50000; i++) {
      bytes = sha256.convert(bytes).bytes;
    }
    return Uint8List.fromList(bytes);
  }

  /// Collects all config + credentials, encrypts with AES-256-CBC, returns
  /// a JSON string suitable for writing to a .homelabbackup file.
  static Future<String> export(String passphrase) async {
    final prefs = await SharedPreferences.getInstance();
    final prefsData = <String, dynamic>{};
    for (final key in _prefKeys) {
      final val = prefs.get(key);
      if (val != null) prefsData[key] = val;
    }

    final allSecure = await _secureStorage.readAll();
    final secureData = <String, String>{};
    for (final e in allSecure.entries) {
      if (_includeSecureKey(e.key)) secureData[e.key] = e.value;
    }

    final payload = jsonEncode({'prefs': prefsData, 'secure': secureData});

    final rng = Random.secure();
    final salt = List.generate(16, (_) => rng.nextInt(256));
    final iv = IV.fromSecureRandom(16);
    final key = Key(_deriveKey(passphrase, salt));
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(payload, iv: iv);

    return jsonEncode({
      'v': _kVersion,
      'ts': DateTime.now().toIso8601String(),
      'salt': base64.encode(salt),
      'iv': base64.encode(iv.bytes),
      'data': encrypted.base64,
    });
  }

  /// Decrypts a .homelabbackup file content and restores all config +
  /// credentials. Throws [FormatException] on wrong passphrase or bad file.
  static Future<void> importBackup(String content, String passphrase) async {
    final Map<String, dynamic> envelope;
    try {
      envelope = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      throw const FormatException('Fichier invalide ou corrompu');
    }

    if ((envelope['v'] as int?) != _kVersion) {
      throw const FormatException('Format de sauvegarde non supporté');
    }

    final salt = base64.decode(envelope['salt'] as String);
    final iv = IV.fromBase64(envelope['iv'] as String);
    final encryptedData = Encrypted.fromBase64(envelope['data'] as String);

    final key = Key(_deriveKey(passphrase, salt));
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    Map<String, dynamic> payload;
    try {
      final decrypted = encrypter.decrypt(encryptedData, iv: iv);
      payload = jsonDecode(decrypted) as Map<String, dynamic>;
    } catch (_) {
      throw const FormatException('Passphrase incorrecte ou fichier corrompu');
    }

    final prefs = await SharedPreferences.getInstance();
    final prefsData = payload['prefs'] as Map<String, dynamic>? ?? {};
    for (final e in prefsData.entries) {
      if (!_prefKeys.contains(e.key)) continue;
      final val = e.value;
      if (val is bool) {
        await prefs.setBool(e.key, val);
      } else if (val is int) {
        await prefs.setInt(e.key, val);
      } else if (val is double) {
        await prefs.setDouble(e.key, val);
      } else if (val is String) {
        await prefs.setString(e.key, val);
      }
    }

    final secureData = payload['secure'] as Map<String, dynamic>? ?? {};
    for (final e in secureData.entries) {
      if (!_includeSecureKey(e.key)) continue;
      await _secureStorage.write(key: e.key, value: e.value as String);
    }
  }
}
