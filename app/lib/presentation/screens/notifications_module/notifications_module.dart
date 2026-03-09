import 'package:flutter_modular/flutter_modular.dart';
import 'package:inbota/modules/shared_module.dart';
import 'package:inbota/presentation/routes/app_routes.dart';
import 'package:inbota/presentation/screens/notifications_module/controller/notifications_controller.dart';
import 'package:inbota/presentation/screens/notifications_module/pages/notifications_page.dart';

class NotificationsModule extends Module {
  @override
  List<Module> get imports => [SharedModule()];

  @override
  void binds(Injector i) {
    i.addSingleton<NotificationsController>(NotificationsController.new);
  }

  @override
  void routes(RouteManager r) {
    r.child(AppRoutes.splash, child: (_) => const NotificationsPage());
  }
}
