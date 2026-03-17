import 'package:flutter_modular/flutter_modular.dart';
import 'package:organiq/modules/shared_module.dart';
import 'package:organiq/presentation/routes/app_routes.dart';
import 'package:organiq/presentation/screens/reminders_module/controller/reminders_controller.dart';
import 'package:organiq/presentation/screens/reminders_module/pages/reminders_page.dart';

class RemindersModule extends Module {
  @override
  List<Module> get imports => [SharedModule()];

  @override
  void binds(Injector i) {
    i.addSingleton<RemindersController>(RemindersController.new);
  }

  @override
  void routes(RouteManager r) {
    r.child(
      AppRoutes.splash,
      child: (_) => const RemindersPage(),
      transition: TransitionType.noTransition,
      duration: Duration.zero,
    );
  }
}
