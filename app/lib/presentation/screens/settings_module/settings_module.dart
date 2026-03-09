import 'package:flutter_modular/flutter_modular.dart';
import 'package:inbota/modules/shared_module.dart';
import 'package:inbota/presentation/routes/app_routes.dart';
import 'package:inbota/presentation/screens/settings_module/controller/settings_account_controller.dart';
import 'package:inbota/presentation/screens/settings_module/controller/settings_contexts_controller.dart';
import 'package:inbota/presentation/screens/settings_module/controller/settings_controller.dart';
import 'package:inbota/presentation/screens/settings_module/controller/settings_notifications_controller.dart';
import 'package:inbota/presentation/screens/settings_module/pages/settings_account_page.dart';
import 'package:inbota/presentation/screens/settings_module/pages/settings_components_page.dart';
import 'package:inbota/presentation/screens/settings_module/pages/settings_contexts_page.dart';
import 'package:inbota/presentation/screens/settings_module/pages/settings_notifications_page.dart';
import 'package:inbota/presentation/screens/settings_module/pages/settings_page.dart';

class SettingsModule extends Module {
  // core_modules
  @override
  List<Module> get imports => [SharedModule()];

  @override
  void binds(Injector i) {
    i.addSingleton<SettingsController>(SettingsController.new);
    i.addSingleton<SettingsAccountController>(SettingsAccountController.new);
    i.addSingleton<SettingsContextsController>(SettingsContextsController.new);
    i.addSingleton<SettingsNotificationsController>(SettingsNotificationsController.new);
  }

  @override
  void routes(RouteManager r) {
    r.child(AppRoutes.splash, child: (_) => const SettingsPage());
    r.child(AppRoutes.account, child: (_) => const SettingsAccountPage());
    r.child(AppRoutes.components, child: (_) => const SettingsComponentsPage());
    r.child(AppRoutes.contexts, child: (_) => const SettingsContextsPage());
    r.child(AppRoutes.notifications, child: (_) => const SettingsNotificationsPage());
  }
}
