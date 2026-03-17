import 'package:flutter_modular/flutter_modular.dart';
import 'package:organiq/modules/shared_module.dart';
import 'package:organiq/presentation/routes/app_routes.dart';
import 'package:organiq/presentation/screens/shopping_module/controller/shopping_controller.dart';
import 'package:organiq/presentation/screens/shopping_module/pages/shopping_page.dart';

class ShoppingModule extends Module {
  @override
  List<Module> get imports => [SharedModule()];

  @override
  void binds(Injector i) {
    i.addSingleton<ShoppingController>(ShoppingController.new);
  }

  @override
  void routes(RouteManager r) {
    r.child(
      AppRoutes.splash,
      child: (_) => const ShoppingPage(),
      transition: TransitionType.noTransition,
      duration: Duration.zero,
    );
  }
}
