import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Securely stores sensitive data (API keys) using platform-native keychains.
///
/// - Windows: Credential Manager / DPAPI
/// - macOS: Keychain
/// - Linux: libsecret (Secret Service API)
/// - Android: EncryptedSharedPreferences
/// - iOS: Keychain
class ApiKeyStore {
  final FlutterSecureStorage _storage;
  static const _prefix = 'server_api_key_';

  ApiKeyStore()
      : _storage = const FlutterSecureStorage();

  /// Save an API key for the given server config ID.
  Future<void> save(String serverConfigId, String apiKey) async {
    await _storage.write(key: '$_prefix$serverConfigId', value: apiKey);
  }

  /// Retrieve the API key for the given server config ID, or null if none.
  Future<String?> get(String serverConfigId) async {
    return _storage.read(key: '$_prefix$serverConfigId');
  }

  /// Delete the API key for the given server config ID.
  Future<void> delete(String serverConfigId) async {
    await _storage.delete(key: '$_prefix$serverConfigId');
  }

  /// Delete all stored API keys.
  Future<void> clearAll() async {
    final all = await _storage.readAll();
    for (final key in all.keys.where((k) => k.startsWith(_prefix))) {
      await _storage.delete(key: key);
    }
  }
}
