import 'package:flutter_modular/flutter_modular.dart';
import 'package:inbota/modules/shared_module.dart';

import '../screens/auth_module/auth_module.dart';
import '../screens/root_module/root_module.dart';
import '../screens/settings_module/settings_module.dart';
import '../screens/splash_module/splash_module.dart';
import 'app_routes.dart';

class AppModule extends Module {
  @override
  List<Module> get imports => [SharedModule()];

  @override
  void routes(RouteManager r) {
    r.module(AppRoutes.splash, module: SplashModule());
    r.module(AppRoutes.auth, module: AuthModule());
    r.module(AppRoutes.root, module: RootModule());
    r.module(AppRoutes.settings, module: SettingsModule());
    r.redirect('/**', to: AppRoutes.splash);
  }
}
