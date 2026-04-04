import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:organiq/modules/notifications/domain/repositories/i_notifications_repository.dart';
import 'package:organiq/presentation/routes/app_navigation.dart';
import 'package:organiq/presentation/routes/app_routes.dart';
import 'package:organiq/presentation/screens/splash_module/controller/splash_controller.dart';
import 'package:organiq/shared/components/oq_lib/oq_button.dart';
import 'package:organiq/shared/components/oq_lib/oq_loader.dart';
import 'package:organiq/shared/components/oq_lib/oq_text.dart';
import 'package:organiq/shared/services/app_config/app_config_service.dart';
import 'package:organiq/shared/services/push/push_notification_service.dart';
import 'package:organiq/shared/state/oq_state.dart';
import 'package:organiq/shared/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends OQState<SplashPage, SplashController> {
  @override
  void initState() {
    super.initState();
    controller.updateConfig.addListener(_onUpdateConfigChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    controller.updateConfig.removeListener(_onUpdateConfigChanged);
    super.dispose();
  }

  void _onUpdateConfigChanged() {
    final config = controller.updateConfig.value;
    if (config != null && mounted) {
      _showUpdateBottomSheet(config, controller.isMandatoryUpdate.value);
    }
  }

  Future<void> _bootstrap() async {
    final result = await controller.check();

    if (result == null && controller.updateConfig.value == null) return;
    if (result == null) return;

    if (result && mounted) {
      final pushService = PushNotificationService.instance;
      pushService.setRepository(Modular.get<INotificationsRepository>());
      await pushService.initialize();
    }

    if (!mounted) return;
    AppNavigation.replace(
      result == true ? AppRoutes.rootHome : AppRoutes.auth,
    );
    if (result == true) {
      PushNotificationService.instance.consumePendingNavigation();
    }
  }

  void _showUpdateBottomSheet(AppAIConfig config, bool isMandatory) {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: !isMandatory,
      enableDrag: !isMandatory,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PopScope(
          canPop: !isMandatory,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const Icon(
                  Icons.system_update_alt_rounded,
                  size: 48,
                  color: AppColors.primary700,
                ),
                const SizedBox(height: 16),
                OQText(
                  isMandatory ? 'Atualização Obrigatória' : 'Nova Versão Disponível',
                  context: context,
                ).titulo.build(),
                const SizedBox(height: 12),
                OQText(
                  isMandatory
                      ? 'Para continuar usando o Organiq, você precisa atualizar para a versão mais recente (${config.minMandatoryVersion}).'
                      : 'Uma nova versão do Organiq está disponível (${config.latestSuggestedVersion}). Deseja atualizar agora?',
                  context: context,
                ).body.align(TextAlign.center).color(AppColors.textMuted).build(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OQButton(
                    label: 'Atualizar Agora',
                    onPressed: () => _launchStore(config),
                  ),
                ),
                const SizedBox(height: 6),
                if (!isMandatory) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OQButton(
                      label: 'Mais Tarde',
                      variant: OQButtonVariant.ghost,
                      onPressed: () {
                        AppNavigation.pop(null, context);
                        _proceedAfterSuggestedUpdate();
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _proceedAfterSuggestedUpdate() async {
    final result = await controller.check();
    if (result == null) return;
    if (!mounted) return;

    AppNavigation.replace(
      result == true ? AppRoutes.rootHome : AppRoutes.auth,
    );
  }

  Future<void> _launchStore(AppAIConfig config) async {
    final url = Platform.isAndroid ? config.storeAndroidUrl : config.storeIosUrl;
    if (url.isEmpty) return;

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/app_icon.png', width: 160, height: 160),
                const SizedBox(height: 24),
                ValueListenableBuilder<bool>(
                  valueListenable: controller.loading,
                  builder: (context, loading, _) {
                    if (loading) {
                      return const OQLoader(label: 'Conectando...');
                    }
                    return const SizedBox.shrink();
                  },
                ),
                ValueListenableBuilder<String?>(
                  valueListenable: controller.error,
                  builder: (context, error, _) {
                    if (error == null || error.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: OQText(error, context: context).body
                          .align(TextAlign.center)
                          .color(AppColors.textMuted)
                          .build(),
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: controller.loading,
                  builder: (context, loading, _) {
                    if (loading) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: OQButton(
                        label: 'Tentar novamente',
                        onPressed: _bootstrap,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
