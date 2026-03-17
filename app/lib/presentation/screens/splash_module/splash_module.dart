import 'package:flutter_modular/flutter_modular.dart';
import 'package:organiq/modules/shared_module.dart';
import 'package:organiq/presentation/routes/app_routes.dart';
import 'package:organiq/presentation/screens/splash_module/controller/splash_controller.dart';
import 'package:organiq/presentation/screens/splash_module/pages/splash_page.dart';

class SplashModule extends Module {
  // core_modules
  @override
  List<Module> get imports => [SharedModule()];

  @override
  void binds(Injector i) {
    i.addSingleton<SplashController>(SplashController.new);
  }

  @override
  void routes(RouteManager r) {
    r.child(AppRoutes.splash, child: (_) => const SplashPage());
  }
}
