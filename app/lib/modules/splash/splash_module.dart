import 'package:organiq/modules/splash/data/repositories/splash_repository.dart';
import 'package:organiq/modules/splash/domain/repositories/i_splash_repository.dart';
import 'package:organiq/modules/splash/domain/usecases/check_health_usecase.dart';

class SplashModule {
  static void binds(i) {
    // repository
    i.addLazySingleton<ISplashRepository>(SplashRepository.new);

    // usecases
    i.addLazySingleton<CheckHealthUsecase>(CheckHealthUsecase.new);
  }
}
