import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:organiq/presentation/routes/app_navigation.dart';
import 'package:organiq/presentation/routes/app_routes.dart';
import 'package:organiq/presentation/screens/settings_module/controller/settings_controller.dart';
import 'package:organiq/shared/components/oq_lib/index.dart';
import 'package:organiq/shared/state/oq_state.dart';
import 'package:organiq/shared/tutorial/tutorial_controller.dart';
import 'package:organiq/shared/tutorial/tutorial_launcher.dart';
import 'package:organiq/shared/tutorial/tutorial_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends OQState<SettingsPage, SettingsController> {
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

  void _restartTutorial(BuildContext settingsContext) {
    final tutorialController = Modular.get<TutorialController>();
    final tutorialService = Modular.get<TutorialService>();
    // Capture the overlay before popping — it belongs to the root navigator
    // which outlives the settings page.
    final overlayState = Overlay.of(settingsContext);

    AppNavigation.pop(null, settingsContext);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      AppNavigation.navigate('/root/home/');
      await Future<void>.delayed(const Duration(milliseconds: 350));
      await TutorialLauncher.relaunchWithOverlay(
        overlayState: overlayState,
        controller: tutorialController,
        service: tutorialService,
      );
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OQLightAppBar(title: 'Configurações'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OQText('Configurações', context: context).subtitulo.build(),
              const SizedBox(height: 12),
              OQMenuCard(
                items: [
                  OQMenuItem(
                    title: 'Conta',
                    subtitle: 'Dados pessoais e segurança',
                    icon: OQIcon.personOutline,
                    onTap: () => AppNavigation.push(AppRoutes.settingsAccount),
                  ),
                  OQMenuItem(
                    title: 'Notificações',
                    subtitle: 'Lembretes e alertas',
                    icon: OQIcon.notificationsNoneOutlined,
                    onTap: () =>
                        AppNavigation.push(AppRoutes.settingsNotifications),
                  ),
                  // OQMenuItem(
                  //   title: 'Preferências',
                  //   subtitle: 'Idioma e aparência',
                  //   icon: OQIcon.tune,
                  //   onTap: () {},
                  // ),
                  OQMenuItem(
                    title: 'Contextos',
                    subtitle: 'Gerenciar flags e subflags',
                    icon: OQIcon.gridViewRounded,
                    onTap: () => AppNavigation.push(AppRoutes.settingsContexts),
                  ),
                  OQMenuItem(
                    title: 'Tutorial',
                    subtitle: 'Ver o tutorial de introdução novamente',
                    icon: OQIcon.autoAwesomeRounded,
                    onTap: () => _restartTutorial(context),
                  ),
                  // OQMenuItem(
                  //   title: 'Componentes',
                  //   subtitle: 'Biblioteca visual',
                  //   icon: OQIcon.starRounded,
                  //   onTap: () =>
                  //       AppNavigation.push(AppRoutes.settingsComponents),
                  // ),
                ],
              ),
              const SizedBox(height: 20),
              // OQText('Suporte', context: context).subtitulo.build(),
              // const SizedBox(height: 12),
              // OQMenuCard(
              //   items: [
              //     OQMenuItem(
              //       title: 'Central de ajuda',
              //       subtitle: 'Perguntas frequentes',
              //       icon: OQIcon.helpOutline,
              //       onTap: () {},
              //       iconColor: AppColors.ai600,
              //     ),
              //     OQMenuItem(
              //       title: 'Privacidade',
              //       subtitle: 'Termos e políticas',
              //       icon: OQIcon.privacyTipOutlined,
              //       onTap: () {},
              //       iconColor: AppColors.ai600,
              //     ),
              //   ],
              // ),
              // const SizedBox(height: 24),
              if (_versionLabel != null) ...[
                Center(
                  child: OQText(
                    _versionLabel!,
                    context: context,
                  ).caption.build(),
                ),
                const SizedBox(height: 12),
              ],
              ValueListenableBuilder<bool>(
                valueListenable: controller.loading,
                builder: (context, loading, _) {
                  return OQButton(
                    label: 'Sair',
                    loading: loading,
                    onPressed: () async => await controller.logout(),
                    variant: OQButtonVariant.secondary,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
