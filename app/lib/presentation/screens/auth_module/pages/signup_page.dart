import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:organiq/modules/notifications/domain/repositories/i_notifications_repository.dart';
import 'package:organiq/presentation/routes/app_navigation.dart';
import 'package:organiq/presentation/routes/app_routes.dart';
import 'package:organiq/presentation/screens/auth_module/controller/signup_controller.dart';
import 'package:organiq/presentation/screens/auth_module/components/auth_form_scaffold.dart';
import 'package:organiq/shared/components/oq_lib/index.dart';
import 'package:organiq/shared/services/push/push_notification_service.dart';
import 'package:organiq/shared/state/oq_state.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends OQState<SignupPage, SignupController> {
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
      OQSnackBar.error(context, error);
    }
  }

  Future<void> _submit() async {
    final locale = WidgetsBinding.instance.platformDispatcher.locale
        .toLanguageTag();
    final timezone = DateTime.now().timeZoneName;
    final success = await controller.submit(locale: locale, timezone: timezone);
    if (!success || !mounted) return;

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
      title: 'Criar conta',
      subtitle: 'Monte sua rotina inteligente em poucos passos.',
      fields: [
        OQTextField(
          label: 'Nome completo',
          hint: 'Como podemos te chamar?',
          autofillHints: const [AutofillHints.name],
          prefixIcon: const OQIcon(
            OQIcon.personOutline,
            color: AppColors.textMuted,
          ),
          controller: controller.nameController,
        ),
        const SizedBox(height: 16),
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
          hint: 'Crie uma senha segura',
          obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
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
            label: 'Criar conta',
            loading: loading,
            onPressed: _submit,
          );
        },
      ),
      secondaryAction: OQButton(
        label: 'Já tenho conta',
        variant: OQButtonVariant.ghost,
        onPressed: () => AppNavigation.push(AppRoutes.login),
      ),
    );
  }
}
