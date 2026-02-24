import 'package:flutter/material.dart';
import 'package:inbota/modules/auth/data/models/auth_signup_input.dart';
import 'package:inbota/modules/auth/domain/usecases/signup_usecase.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/state/ib_state.dart';
import 'package:inbota/shared/utils/validators.dart';

class SignupController implements IBController {
  final SignupUsecase _signupUsecase;

  SignupController(this._signupUsecase);

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);

  Future<bool> submit({required String locale, required String timezone}) async {
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
      error.value = validationError;
      return false;
    }

    loading.value = true;
    error.value = null;

    final result = await _signupUsecase.call(AuthSignupInput(
      email: email,
      password: password,
      displayName: name,
      locale: locale,
      timezone: timezone,
    ));

    loading.value = false;

    return result.fold((failure) {
      error.value = _failureMessage(failure, fallback: 'Não foi possível criar a conta agora.');
      return false;
    }, (_) => true);
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
    return failure.message?.trim().isNotEmpty == true ? failure.message! : fallback;
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
