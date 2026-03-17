import 'package:flutter/material.dart';
import 'package:organiq/presentation/routes/app_navigation.dart';
import 'package:organiq/presentation/routes/app_routes.dart';
import 'package:organiq/presentation/screens/settings_module/controller/settings_controller.dart';
import 'package:organiq/shared/components/oq_lib/index.dart';
import 'package:organiq/shared/state/oq_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends OQState<SettingsPage, SettingsController> {
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
