import 'package:flutter/material.dart';
import 'package:inbota/modules/auth/data/models/auth_login_input.dart';
import 'package:inbota/modules/auth/domain/usecases/login_usecase.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/state/ib_state.dart';
import 'package:inbota/shared/utils/validators.dart';

class LoginController implements IBController {
  LoginController(this._loginUsecase);

  final LoginUsecase _loginUsecase;

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
      error.value = validationError;
      return false;
    }

    loading.value = true;
    error.value = null;

    final result = await _loginUsecase.call(AuthLoginInput(email: email, password: password));
    loading.value = false;

    return result.fold((failure) {
      error.value = _failureMessage(failure, fallback: 'Não foi possível entrar agora.');
      return false;
    }, (_) => true);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    loading.dispose();
    error.dispose();
  }

  String _failureMessage(Failure failure, {required String fallback}) {
    return failure.message?.trim().isNotEmpty == true ? failure.message! : fallback;
  }

  String? _validate({required String email, required String password}) {
    return Validators.email(email) ?? Validators.password(password);
  }
}
