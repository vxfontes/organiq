import 'package:flutter/material.dart';
import 'package:inbota/presentation/routes/app_navigation.dart';
import 'package:inbota/presentation/routes/app_routes.dart';
import 'package:inbota/presentation/screens/settings_module/controller/settings_controller.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/state/ib_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends IBState<SettingsPage, SettingsController> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const IBLightAppBar(title: 'Configurações'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IBText('Configurações', context: context).subtitulo.build(),
              const SizedBox(height: 12),
              IBMenuCard(
                items: [
                  IBMenuItem(
                    title: 'Conta',
                    subtitle: 'Dados pessoais e segurança',
                    icon: IBIcon.personOutline,
                    onTap: () => AppNavigation.push(AppRoutes.settingsAccount),
                  ),
                  // IBMenuItem(
                  //   title: 'Notificações',
                  //   subtitle: 'Lembretes e alertas',
                  //   icon: IBIcon.notificationsNoneOutlined,
                  //   onTap: () {},
                  // ),
                  // IBMenuItem(
                  //   title: 'Preferências',
                  //   subtitle: 'Idioma e aparência',
                  //   icon: IBIcon.tune,
                  //   onTap: () {},
                  // ),
                  IBMenuItem(
                    title: 'Contextos',
                    subtitle: 'Gerenciar flags e subflags',
                    icon: IBIcon.gridViewRounded,
                    onTap: () => AppNavigation.push(AppRoutes.settingsContexts),
                  ),
                  // IBMenuItem(
                  //   title: 'Componentes',
                  //   subtitle: 'Biblioteca visual',
                  //   icon: IBIcon.starRounded,
                  //   onTap: () =>
                  //       AppNavigation.push(AppRoutes.settingsComponents),
                  // ),
                ],
              ),
              const SizedBox(height: 20),
              // IBText('Suporte', context: context).subtitulo.build(),
              // const SizedBox(height: 12),
              // IBMenuCard(
              //   items: [
              //     IBMenuItem(
              //       title: 'Central de ajuda',
              //       subtitle: 'Perguntas frequentes',
              //       icon: IBIcon.helpOutline,
              //       onTap: () {},
              //       iconColor: AppColors.ai600,
              //     ),
              //     IBMenuItem(
              //       title: 'Privacidade',
              //       subtitle: 'Termos e políticas',
              //       icon: IBIcon.privacyTipOutlined,
              //       onTap: () {},
              //       iconColor: AppColors.ai600,
              //     ),
              //   ],
              // ),
              // const SizedBox(height: 24),
              ValueListenableBuilder<bool>(
                valueListenable: controller.loading,
                builder: (context, loading, _) {
                  return IBButton(
                    label: 'Sair',
                    loading: loading,
                    onPressed: () async => await controller.logout(),
                    variant: IBButtonVariant.secondary,
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
