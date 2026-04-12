import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  const TokenStorage({FlutterSecureStorage? secureStorage})
    : _storage = secureStorage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(
              encryptedSharedPreferences: true,
            ),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  static const _tokenKey = 'auth_token';

  final FlutterSecureStorage _storage;

  Future<String?> readToken() {
    return _storage.read(key: _tokenKey);
  }

  Future<void> saveToken(String token) {
    return _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clearToken() {
    return _storage.delete(key: _tokenKey);
  }
}
