import 'package:flutter_modular/flutter_modular.dart';
import 'package:organiq/modules/shared_module.dart';
import 'package:organiq/presentation/routes/app_routes.dart';
import 'package:organiq/presentation/screens/events_module/controller/events_controller.dart';
import 'package:organiq/presentation/screens/events_module/pages/events_page.dart';

class EventsModule extends Module {
  @override
  List<Module> get imports => [SharedModule()];

  @override
  void binds(Injector i) {
    i.addSingleton<EventsController>(EventsController.new);
  }

  @override
  void routes(RouteManager r) {
    r.child(
      AppRoutes.splash,
      child: (_) => const EventsPage(),
      transition: TransitionType.noTransition,
      duration: Duration.zero,
    );
  }
}
