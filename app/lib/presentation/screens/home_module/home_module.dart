import 'package:flutter_modular/flutter_modular.dart';
import 'package:organiq/modules/shared_module.dart';
import 'package:organiq/presentation/routes/app_routes.dart';
import 'package:organiq/presentation/screens/home_module/controller/home_controller.dart';
import 'package:organiq/presentation/screens/home_module/pages/home_page.dart';

class HomeModule extends Module {
  @override
  List<Module> get imports => [SharedModule()];

  @override
  void binds(Injector i) {
    i.addLazySingleton<HomeController>(HomeController.new);
  }

  @override
  void routes(RouteManager r) {
    r.child(
      AppRoutes.splash,
      child: (_) => const HomePage(),
      transition: TransitionType.noTransition,
      duration: Duration.zero,
    );
  }
}
