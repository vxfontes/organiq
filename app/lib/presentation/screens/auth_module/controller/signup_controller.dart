import 'package:flutter/material.dart';
import 'package:organiq/modules/auth/data/models/auth_signup_input.dart';
import 'package:organiq/modules/auth/domain/usecases/signup_usecase.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/services/analytics/app_monitoring_service.dart';
import 'package:organiq/shared/services/analytics/screen_log_service.dart';
import 'package:organiq/shared/services/timezone/user_timezone_service.dart';
import 'package:organiq/shared/state/oq_state.dart';
import 'package:organiq/shared/utils/validators.dart';

class SignupController implements OQController {
  final SignupUsecase _signupUsecase;
  final AppMonitoringService _monitoringService;
  final ScreenLogService _screenLogService;

  SignupController(
    this._signupUsecase,
    this._monitoringService,
    this._screenLogService,
  );

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);

  Future<bool> submit({
    required String locale,
    required String timezone,
  }) async {
    if (loading.value) return false;
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final validationError = _validate(
      name: name,
      email: email,
      password: password,
      locale: locale,
      timezone: timezone,
    );
    if (validationError != null) {
      _screenLogService.logFlowStep(
        flowName: 'auth_signup',
        flowStep: 'validation_failed',
        action: 'submit_signup',
        result: 'failure',
        origin: 'signup_controller',
      );
      error.value = validationError;
      return false;
    }

    _screenLogService.logFlowStep(
      flowName: 'auth_signup',
      flowStep: 'submit_started',
      action: 'submit_signup',
      result: 'started',
      origin: 'signup_controller',
    );
    loading.value = true;
    error.value = null;

    final result = await _signupUsecase.call(
      AuthSignupInput(
        email: email,
        password: password,
        displayName: name,
        locale: locale,
        timezone: timezone,
      ),
    );

    loading.value = false;

    if (result.isLeft()) {
      final failure = result.swap().getOrElse(() => SaveFailure());
      _screenLogService.logFlowStep(
        flowName: 'auth_signup',
        flowStep: 'submit_finished',
        action: 'submit_signup',
        result: 'failure',
        origin: 'signup_controller',
      );
      await _monitoringService.logEvent(
        'auth_signup_failed',
        parameters: <String, Object?>{
          'failure_type': failure.runtimeType.toString(),
        },
      );
      error.value = _failureMessage(
        failure,
        fallback: 'Não foi possível criar a conta agora.',
      );
      return false;
    }

    final session = result.getOrElse(() => throw StateError('Missing session'));
    UserTimezoneService.instance.setTimezone(session.user.timezone);
    _screenLogService.logFlowStep(
      flowName: 'auth_signup',
      flowStep: 'submit_finished',
      action: 'submit_signup',
      result: 'success',
      origin: 'signup_controller',
    );
    await _monitoringService.identifyUser(userId: session.user.id);
    await _monitoringService.logEvent('auth_signup_success');
    return true;
  }

  @override
  void dispose() {
    nameController.dispose();
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

  String? _validate({
    required String name,
    required String email,
    required String password,
    required String locale,
    required String timezone,
  }) {
    return Validators.name(name) ??
        Validators.email(email) ??
        Validators.password(password) ??
        Validators.localeAndTimezone(locale: locale, timezone: timezone);
  }
}
