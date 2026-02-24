import 'package:flutter/material.dart';
import 'package:inbota/modules/auth/domain/usecases/logout_usecase.dart';
import 'package:inbota/presentation/routes/app_navigation.dart';
import 'package:inbota/presentation/routes/app_routes.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/state/ib_state.dart';

class SettingsController implements IBController {
  SettingsController(this._logoutUsecase);

  final LogoutUsecase _logoutUsecase;

  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);

  Future<bool> fetchLogout() async {
    if (loading.value) return false;
    loading.value = true;
    error.value = null;

    final result = await _logoutUsecase.call();
    loading.value = false;

    return result.fold((failure) {
      error.value = _failureMessage(
        failure,
        fallback: 'Não foi possível sair agora.',
      );
      return false;
    }, (_) => true);
  }

  Future<void> logout() async {
    final success = await fetchLogout();
    if (!success) return;
    AppNavigation.clearAndPush(AppRoutes.auth);
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
