import 'package:flutter_modular/flutter_modular.dart';
import 'package:organiq/modules/shared_module.dart';
import 'package:organiq/presentation/routes/app_routes.dart';
import 'package:organiq/presentation/screens/settings_module/controller/settings_account_controller.dart';
import 'package:organiq/presentation/screens/settings_module/controller/settings_contexts_controller.dart';
import 'package:organiq/presentation/screens/settings_module/controller/settings_controller.dart';
import 'package:organiq/presentation/screens/settings_module/controller/settings_notifications_controller.dart';
import 'package:organiq/presentation/screens/settings_module/pages/settings_account_page.dart';
import 'package:organiq/presentation/screens/settings_module/pages/settings_components_page.dart';
import 'package:organiq/presentation/screens/settings_module/pages/settings_contexts_page.dart';
import 'package:organiq/presentation/screens/settings_module/pages/settings_notifications_page.dart';
import 'package:organiq/presentation/screens/settings_module/pages/settings_page.dart';

class SettingsModule extends Module {
  // core_modules
  @override
  List<Module> get imports => [SharedModule()];

  @override
  void binds(Injector i) {
    i.addLazySingleton<SettingsController>(SettingsController.new);
    i.addLazySingleton<SettingsAccountController>(SettingsAccountController.new);
    i.addLazySingleton<SettingsContextsController>(SettingsContextsController.new);
    i.addLazySingleton<SettingsNotificationsController>(
      SettingsNotificationsController.new,
    );
  }

  @override
  void routes(RouteManager r) {
    r.child(AppRoutes.splash, child: (_) => const SettingsPage());
    r.child(AppRoutes.account, child: (_) => const SettingsAccountPage());
    r.child(AppRoutes.components, child: (_) => const SettingsComponentsPage());
    r.child(AppRoutes.contexts, child: (_) => const SettingsContextsPage());
    r.child(
      AppRoutes.notifications,
      child: (_) => const SettingsNotificationsPage(),
    );
  }
}
