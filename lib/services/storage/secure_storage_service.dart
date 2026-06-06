import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  Future<void> saveApiKey(String provider, String key) async {
    await _storage.write(
      key: '${AppConstants.secureStoragePrefix}api_key_$provider',
      value: key,
    );
  }

  Future<String?> readApiKey(String provider) async {
    return await _storage.read(
      key: '${AppConstants.secureStoragePrefix}api_key_$provider',
    );
  }

  Future<void> deleteApiKey(String provider) async {
    await _storage.delete(
      key: '${AppConstants.secureStoragePrefix}api_key_$provider',
    );
  }

  Future<void> saveOAuthToken(String email, String token) async {
    await _storage.write(
      key: '${AppConstants.secureStoragePrefix}oauth_$email',
      value: token,
    );
  }

  Future<String?> readOAuthToken(String email) async {
    return await _storage.read(
      key: '${AppConstants.secureStoragePrefix}oauth_$email',
    );
  }

  Future<void> deleteOAuthToken(String email) async {
    await _storage.delete(
      key: '${AppConstants.secureStoragePrefix}oauth_$email',
    );
  }

  Future<void> saveImapPassword(String email, String password) async {
    await _storage.write(
      key: '${AppConstants.secureStoragePrefix}imap_$email',
      value: password,
    );
  }

  Future<String?> readImapPassword(String email) async {
    return await _storage.read(
      key: '${AppConstants.secureStoragePrefix}imap_$email',
    );
  }

  Future<bool> hasAnyApiKey() async {
    for (final provider in ['gemini', 'openai', 'claude']) {
      final key = await readApiKey(provider);
      if (key != null && key.isNotEmpty) return true;
    }
    return false;
  }

  Future<Map<String, String?>> getAllApiKeys() async {
    return {
      'gemini': await readApiKey('gemini'),
      'openai': await readApiKey('openai'),
      'claude': await readApiKey('claude'),
    };
  }
}
