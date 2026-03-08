import 'package:flutter/material.dart';
import 'package:inbota/presentation/routes/app_navigation.dart';
import 'package:inbota/presentation/routes/app_routes.dart';
import 'package:inbota/presentation/screens/auth_module/controller/login_controller.dart';
import 'package:inbota/presentation/screens/auth_module/components/auth_form_scaffold.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/state/ib_state.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends IBState<LoginPage, LoginController> {
  @override
  void initState() {
    super.initState();
    controller.error.addListener(_onErrorChanged);
  }

  @override
  void dispose() {
    controller.error.removeListener(_onErrorChanged);
    super.dispose();
  }

  void _onErrorChanged() {
    final error = controller.error.value;
    if (error != null && error.isNotEmpty && mounted) {
      IBSnackBar.error(context, error);
    }
  }

  Future<void> _submit() async {
    final success = await controller.submit();
    if (!success || !mounted) return;
    AppNavigation.clearAndPush(AppRoutes.rootHome);
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormScaffold(
      header: Image.asset(
        'assets/app_icon.png',
        width: 64,
        height: 64,
      ),
      title: 'Entrar',
      subtitle: 'Acesse sua conta para continuar.',
      fields: [
        IBTextField(
          label: 'Email',
          hint: 'voce@exemplo.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const IBIcon(IBIcon.mailOutline, color: AppColors.textMuted),
          controller: controller.emailController,
        ),
        const SizedBox(height: 16),
        IBTextField(
          label: 'Senha',
          hint: 'Digite sua senha',
          obscureText: true,
          prefixIcon: const IBIcon(IBIcon.lockOutline, color: AppColors.textMuted),
          controller: controller.passwordController,
        ),
      ],
      primaryAction: ValueListenableBuilder<bool>(
        valueListenable: controller.loading,
        builder: (context, loading, _) {
          return IBButton(
            label: 'Entrar',
            loading: loading,
            onPressed: _submit,
          );
        },
      ),
      secondaryAction: IBButton(
        label: 'Criar uma conta',
        variant: IBButtonVariant.ghost,
        onPressed: () => AppNavigation.push(AppRoutes.signup),
      ),
    );
  }
}
