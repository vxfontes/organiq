import 'package:flutter_modular/flutter_modular.dart';
import 'package:organiq/modules/shared_module.dart';
import 'package:organiq/presentation/routes/app_routes.dart';
import 'package:organiq/presentation/screens/create_module/controller/create_controller.dart';
import 'package:organiq/presentation/screens/create_module/controller/suggestion_controller.dart';
import 'package:organiq/presentation/screens/create_module/pages/create_page.dart';

class CreateModule extends Module {
  @override
  List<Module> get imports => [SharedModule()];

  @override
  void binds(Injector i) {
    i.addLazySingleton<CreateController>(CreateController.new);
    i.addLazySingleton<SuggestionController>(SuggestionController.new);
  }

  @override
  void routes(RouteManager r) {
    r.child(
      AppRoutes.splash,
      child: (_) => const CreatePage(),
      transition: TransitionType.noTransition,
      duration: Duration.zero,
    );
  }
}
