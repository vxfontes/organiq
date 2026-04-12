import 'package:flutter_modular/flutter_modular.dart';
import 'package:organiq/modules/shared_module.dart';
import 'package:organiq/modules/auth/domain/usecases/get_me_usecase.dart';
import 'package:organiq/modules/splash/domain/usecases/check_health_usecase.dart';
import 'package:organiq/presentation/routes/app_routes.dart';
import 'package:organiq/presentation/screens/splash_module/controller/splash_controller.dart';
import 'package:organiq/presentation/screens/splash_module/pages/splash_page.dart';
import 'package:organiq/shared/services/analytics/app_monitoring_service.dart';
import 'package:organiq/shared/services/analytics/screen_log_service.dart';
import 'package:organiq/shared/services/app_config/app_config_service.dart';
import 'package:organiq/shared/services/cache/cache_service.dart';
import 'package:organiq/shared/storage/auth_token_store.dart';

class SplashModule extends Module {
  // core_modules
  @override
  List<Module> get imports => [SharedModule()];

  @override
  void binds(Injector i) {
    i.addLazySingleton<SplashController>(
      () => SplashController(
        i.get<CheckHealthUsecase>(),
        i.get<AuthTokenStore>(),
        i.get<GetMeUsecase>(),
        i.get<AppMonitoringService>(),
        i.get<ScreenLogService>(),
        i.get<IAppConfigService>(),
        i.get<ICacheService>(),
      ),
    );
  }

  @override
  void routes(RouteManager r) {
    r.child(AppRoutes.splash, child: (_) => const SplashPage());
  }
}
