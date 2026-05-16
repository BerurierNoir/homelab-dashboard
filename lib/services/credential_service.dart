import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CredentialService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static String _usernameKey(String id) => 'cred_${id}_username';
  static String _passwordKey(String id) => 'cred_${id}_password';
  static String _tokenKey(String id) => 'cred_${id}_token';

  Future<String?> getUsername(String serviceId) =>
      _storage.read(key: _usernameKey(serviceId));

  Future<String?> getPassword(String serviceId) =>
      _storage.read(key: _passwordKey(serviceId));

  Future<String?> getToken(String serviceId) =>
      _storage.read(key: _tokenKey(serviceId));

  Future<void> saveUsername(String serviceId, String value) =>
      _storage.write(key: _usernameKey(serviceId), value: value);

  Future<void> savePassword(String serviceId, String value) =>
      _storage.write(key: _passwordKey(serviceId), value: value);

  Future<void> saveToken(String serviceId, String value) =>
      _storage.write(key: _tokenKey(serviceId), value: value);

  Future<void> clearCredentials(String serviceId) async {
    await _storage.delete(key: _usernameKey(serviceId));
    await _storage.delete(key: _passwordKey(serviceId));
    await _storage.delete(key: _tokenKey(serviceId));
  }

  Future<bool> hasCredentials(String serviceId) async {
    final u = await getUsername(serviceId);
    final p = await getPassword(serviceId);
    final t = await getToken(serviceId);
    return (u != null && u.isNotEmpty) ||
        (p != null && p.isNotEmpty) ||
        (t != null && t.isNotEmpty);
  }
}

final credentialService = CredentialService();
