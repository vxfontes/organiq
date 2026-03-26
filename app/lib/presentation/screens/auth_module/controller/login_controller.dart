import 'package:flutter/material.dart';
import 'package:organiq/modules/auth/data/models/auth_login_input.dart';
import 'package:organiq/modules/auth/domain/usecases/login_usecase.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/services/analytics/app_monitoring_service.dart';
import 'package:organiq/shared/services/analytics/screen_log_service.dart';
import 'package:organiq/shared/services/timezone/user_timezone_service.dart';
import 'package:organiq/shared/state/oq_state.dart';
import 'package:organiq/shared/utils/validators.dart';

class LoginController implements OQController {
  LoginController(
    this._loginUsecase,
    this._monitoringService,
    this._screenLogService,
  );

  final LoginUsecase _loginUsecase;
  final AppMonitoringService _monitoringService;
  final ScreenLogService _screenLogService;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);

  Future<bool> submit() async {
    if (loading.value) return false;
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final validationError = _validate(email: email, password: password);
    if (validationError != null) {
      _screenLogService.logFlowStep(
        flowName: 'auth_login',
        flowStep: 'validation_failed',
        action: 'submit_login',
        result: 'failure',
        origin: 'login_controller',
      );
      error.value = validationError;
      return false;
    }

    _screenLogService.logFlowStep(
      flowName: 'auth_login',
      flowStep: 'submit_started',
      action: 'submit_login',
      result: 'started',
      origin: 'login_controller',
    );
    loading.value = true;
    error.value = null;

    final result = await _loginUsecase.call(
      AuthLoginInput(email: email, password: password),
    );
    loading.value = false;

    if (result.isLeft()) {
      final failure = result.swap().getOrElse(() => GetFailure());
      _screenLogService.logFlowStep(
        flowName: 'auth_login',
        flowStep: 'submit_finished',
        action: 'submit_login',
        result: 'failure',
        origin: 'login_controller',
      );
      await _monitoringService.logEvent(
        'auth_login_failed',
        parameters: <String, Object?>{
          'failure_type': failure.runtimeType.toString(),
        },
      );
      error.value = _failureMessage(
        failure,
        fallback: 'Não foi possível entrar agora.',
      );
      return false;
    }

    final session = result.getOrElse(() => throw StateError('Missing session'));
    UserTimezoneService.instance.setTimezone(session.user.timezone);
    _screenLogService.logFlowStep(
      flowName: 'auth_login',
      flowStep: 'submit_finished',
      action: 'submit_login',
      result: 'success',
      origin: 'login_controller',
    );
    await _monitoringService.identifyUser(userId: session.user.id);
    await _monitoringService.logEvent('auth_login_success');
    return true;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    loading.dispose();
    error.dispose();
  }

  String _failureMessage(Failure failure, {required String fallback}) {
    return failure.message?.trim().isNotEmpty == true
        ? failure.message!
        : fallback;
  }

  String? _validate({required String email, required String password}) {
    return Validators.email(email) ?? Validators.password(password);
  }
}
