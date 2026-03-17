import 'package:flutter/foundation.dart';
import 'package:organiq/modules/auth/domain/usecases/get_me_usecase.dart';
import 'package:organiq/modules/splash/domain/usecases/check_health_usecase.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/services/timezone/user_timezone_service.dart';
import 'package:organiq/shared/state/oq_state.dart';
import 'package:organiq/shared/storage/auth_token_store.dart';

class SplashController implements OQController {
  SplashController(
    this._checkHealthUsecase,
    this._tokenStore,
    this._getMeUsecase,
  );

  final CheckHealthUsecase _checkHealthUsecase;
  final AuthTokenStore _tokenStore;
  final GetMeUsecase _getMeUsecase;

  final ValueNotifier<bool> loading = ValueNotifier(true);
  final ValueNotifier<String?> error = ValueNotifier(null);

  Future<bool?> check() async {
    loading.value = true;
    error.value = null;

    try {
      final result = await _checkHealthUsecase.call();
      final healthy = result.fold((failure) {
        error.value = _failureMessage(
          failure,
          fallback: 'Servidor indisponivel. Verifique a rede local.',
        );
        return false;
      }, (_) => true);

      if (!healthy) return null;

      final token = await _tokenStore.readToken();
      if (token == null || token.isEmpty) {
        UserTimezoneService.instance.clear();
        return false;
      }

      final meResult = await _getMeUsecase.call();
      final hasSession = meResult.fold((_) => false, (user) {
        UserTimezoneService.instance.setTimezone(user.timezone);
        return true;
      });
      if (!hasSession) {
        UserTimezoneService.instance.clear();
        await _tokenStore.clearToken();
      }
      return hasSession;
    } finally {
      loading.value = false;
    }
  }

  @override
  void dispose() {
    loading.dispose();
    error.dispose();
  }

  String _failureMessage(Failure failure, {required String fallback}) {
    return failure.message?.trim().isNotEmpty == true
        ? failure.message!
        : fallback;
  }
}
