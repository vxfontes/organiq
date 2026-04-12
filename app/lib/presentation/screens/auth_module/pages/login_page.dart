import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:organiq/modules/notifications/domain/repositories/i_notifications_repository.dart';
import 'package:organiq/presentation/routes/app_navigation.dart';
import 'package:organiq/presentation/routes/app_routes.dart';
import 'package:organiq/presentation/screens/auth_module/controller/login_controller.dart';
import 'package:organiq/presentation/screens/auth_module/components/auth_form_scaffold.dart';
import 'package:organiq/shared/components/oq_lib/index.dart';
import 'package:organiq/shared/services/push/push_notification_service.dart';
import 'package:organiq/shared/state/oq_state.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends OQState<LoginPage, LoginController> {
  String? _versionLabel;

  @override
  void initState() {
    super.initState();
    controller.error.addListener(_onErrorChanged);
    _loadVersionLabel();
  }

  @override
  void dispose() {
    controller.error.removeListener(_onErrorChanged);
    super.dispose();
  }

  void _onErrorChanged() {
    final error = controller.error.value;
    if (error != null && error.isNotEmpty && mounted) {
      OQSnackBar.error(context, error);
    }
  }

  Future<void> _loadVersionLabel() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _versionLabel =
            'Versão ${packageInfo.version}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _versionLabel = null;
      });
    }
  }

  Future<void> _submit() async {
    final success = await controller.submit();
    if (!success || !mounted) return;

    // Initialize Push Notifications
    final pushService = PushNotificationService.instance;
    pushService.setRepository(Modular.get<INotificationsRepository>());
    await pushService.initialize();

    AppNavigation.clearAndPush(AppRoutes.rootHome);
    pushService.consumePendingNavigation();
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormScaffold(
      header: Image.asset('assets/app_icon.png', width: 64, height: 64),
      title: 'Entrar',
      subtitle: 'Acesse sua conta para continuar.',
      fields: [
        OQTextField(
          label: 'Email',
          hint: 'voce@exemplo.com',
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          prefixIcon: const OQIcon(
            OQIcon.mailOutline,
            color: AppColors.textMuted,
          ),
          controller: controller.emailController,
        ),
        const SizedBox(height: 16),
        OQTextField(
          label: 'Senha',
          hint: 'Digite sua senha',
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          prefixIcon: const OQIcon(
            OQIcon.lockOutline,
            color: AppColors.textMuted,
          ),
          controller: controller.passwordController,
        ),
      ],
      primaryAction: ValueListenableBuilder<bool>(
        valueListenable: controller.loading,
        builder: (context, loading, _) {
          return OQButton(
            label: 'Entrar',
            loading: loading,
            onPressed: _submit,
          );
        },
      ),
      secondaryAction: OQButton(
        label: 'Criar uma conta',
        variant: OQButtonVariant.ghost,
        onPressed: () => AppNavigation.push(AppRoutes.signup),
      ),
      footer: _versionLabel == null
          ? null
          : OQText(
              _versionLabel!,
              context: context,
            ).caption.color(AppColors.textMuted).build(),
    );
  }
}
