import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:inbota/modules/notifications/domain/repositories/i_notifications_repository.dart';
import 'package:inbota/presentation/routes/app_navigation.dart';
import 'package:inbota/presentation/routes/app_routes.dart';
import 'package:inbota/presentation/screens/splash_module/controller/splash_controller.dart';
import 'package:inbota/shared/components/ib_lib/ib_button.dart';
import 'package:inbota/shared/components/ib_lib/ib_loader.dart';
import 'package:inbota/shared/components/ib_lib/ib_text.dart';
import 'package:inbota/shared/services/push/push_notification_service.dart';
import 'package:inbota/shared/state/ib_state.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends IBState<SplashPage, SplashController> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final shouldGoHome = await controller.check();
    
    if (shouldGoHome != null && shouldGoHome && mounted) {
      final pushService = PushNotificationService.instance;
      pushService.setRepository(Modular.get<INotificationsRepository>());
      await pushService.initialize();
    }

    if (!mounted) return;
    AppNavigation.replace(shouldGoHome == true ? AppRoutes.rootHome : AppRoutes.auth);
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
                Image.asset(
                  'assets/app_icon.png',
                  width: 160,
                  height: 160,
                ),
                const SizedBox(height: 24),
                ValueListenableBuilder<bool>(
                  valueListenable: controller.loading,
                  builder: (context, loading, _) {
                    if (loading) {
                      return const IBLoader(label: 'Conectando...');
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
                      child: IBText(error, context: context)
                          .body
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
                      child: IBButton(
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
