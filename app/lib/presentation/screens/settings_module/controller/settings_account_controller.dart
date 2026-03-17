import 'package:flutter/material.dart';
import 'package:organiq/modules/auth/data/models/auth_user_model.dart';
import 'package:organiq/modules/auth/domain/usecases/get_me_usecase.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/services/timezone/user_timezone_service.dart';
import 'package:organiq/shared/state/oq_state.dart';

class SettingsAccountController implements OQController {
  SettingsAccountController(this._getMeUsecase);

  final GetMeUsecase _getMeUsecase;

  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);
  final ValueNotifier<AuthUserModel?> user = ValueNotifier(null);

  bool get hasContent => user.value != null;

  @override
  void dispose() {
    loading.dispose();
    error.dispose();
    user.dispose();
  }

  Future<void> load() async {
    if (loading.value) return;
    loading.value = true;
    error.value = null;

    final result = await _getMeUsecase.call();
    loading.value = false;

    result.fold(
      (failure) {
        error.value = _failureMessage(
          failure,
          fallback: 'Não foi possível carregar sua conta.',
        );
      },
      (output) {
        UserTimezoneService.instance.setTimezone(output.timezone);
        user.value = output;
      },
    );
  }

  Future<void> refresh() async {
    await load();
  }

  String _failureMessage(Failure failure, {required String fallback}) {
    return failure.message?.trim().isNotEmpty == true
        ? failure.message!
        : fallback;
  }
}
