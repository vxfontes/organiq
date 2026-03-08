import 'package:flutter_modular/flutter_modular.dart';
import 'package:inbota/modules/shared_module.dart';
import 'package:inbota/presentation/routes/app_routes.dart';
import 'package:inbota/presentation/screens/create_module/create_module.dart';
import 'package:inbota/presentation/screens/events_module/events_module.dart';
import 'package:inbota/presentation/screens/home_module/home_module.dart';
import 'package:inbota/presentation/screens/reminders_module/reminders_module.dart';
import 'package:inbota/presentation/screens/root_module/pages/root_page.dart';
import 'package:inbota/presentation/screens/schedule_module/schedule_module.dart';
import 'package:inbota/presentation/screens/shopping_module/shopping_module.dart';

class RootModule extends Module {
  // core_modules
  @override
  List<Module> get imports => [SharedModule()];

  @override
  void routes(RouteManager r) {
    r.child(
      AppRoutes.splash,
      child: (_) => const RootPage(),
      children: [
        // modulos internos do app
        ModuleRoute(
          AppRoutes.home,
          module: HomeModule(),
          transition: TransitionType.noTransition,
          duration: Duration.zero,
        ),
        ModuleRoute(
          AppRoutes.schedule,
          module: ScheduleModule(),
          transition: TransitionType.noTransition,
          duration: Duration.zero,
        ),
        ModuleRoute(
          AppRoutes.reminders,
          module: RemindersModule(),
          transition: TransitionType.noTransition,
          duration: Duration.zero,
        ),
        ModuleRoute(
          AppRoutes.create,
          module: CreateModule(),
          transition: TransitionType.noTransition,
          duration: Duration.zero,
        ),
        ModuleRoute(
          AppRoutes.shopping,
          module: ShoppingModule(),
          transition: TransitionType.noTransition,
          duration: Duration.zero,
        ),
        ModuleRoute(
          AppRoutes.events,
          module: EventsModule(),
          transition: TransitionType.noTransition,
          duration: Duration.zero,
        ),
      ],
    );
  }
}
