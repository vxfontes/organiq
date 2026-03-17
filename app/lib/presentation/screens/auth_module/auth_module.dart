import 'package:flutter_modular/flutter_modular.dart';
import 'package:organiq/modules/shared_module.dart';
import 'package:organiq/presentation/routes/app_routes.dart';
import 'package:organiq/presentation/screens/auth_module/controller/login_controller.dart';
import 'package:organiq/presentation/screens/auth_module/controller/signup_controller.dart';

import 'pages/login_page.dart';
import 'pages/pre_login_page.dart';
import 'pages/signup_page.dart';

class AuthModule extends Module {
  static const String routeLogin = '/login';
  static const String routeSignup = '/signup';

  // core_modules
  @override
  List<Module> get imports => [SharedModule()];


  @override
  void binds(Injector i) {
    i.addSingleton<LoginController>(LoginController.new);
    i.addSingleton<SignupController>(SignupController.new);
  }

  @override
  void routes(RouteManager r) {
    r.child(AppRoutes.splash, child: (_) => const PreLoginPage());
    r.child(routeLogin, child: (_) => const LoginPage());
    r.child(routeSignup, child: (_) => const SignupPage());
  }
}
