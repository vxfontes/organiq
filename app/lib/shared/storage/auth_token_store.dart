import 'package:organiq/shared/storage/token_storage.dart';

class AuthTokenStore {
  AuthTokenStore(this._storage);

  final TokenStorage _storage;

  String? _cachedToken;

  Future<String?> readToken() async {
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      return _cachedToken;
    }

    final stored = await _storage.readToken();
    if (stored != null && stored.isNotEmpty) {
      _cachedToken = stored;
    }
    return stored;
  }

  Future<void> saveToken(String token) async {
    await _storage.saveToken(token);
    _cachedToken = token;
  }

  Future<void> clearToken() async {
    await _storage.clearToken();
    _cachedToken = null;
  }
}
