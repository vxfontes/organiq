import 'package:organiq/shared/global/global_keys.dart';
import 'package:organiq/shared/global/global_share.dart';
import 'package:organiq/shared/storage/token_storage.dart';

class AuthTokenStore {
  AuthTokenStore(this._storage);

  final TokenStorage _storage;

  Future<String?> readToken() async {
    final cached = GlobalShare.getValue<String>(GlobalKeys.token);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final stored = await _storage.readToken();
    if (stored != null && stored.isNotEmpty) {
      GlobalShare.setValue(GlobalKeys.token, stored);
    }
    return stored;
  }

  Future<void> saveToken(String token) async {
    await _storage.saveToken(token);
    GlobalShare.setValue(GlobalKeys.token, token);
  }

  Future<void> clearToken() async {
    await _storage.clearToken();
    GlobalShare.removeValue(GlobalKeys.token);
  }
}
