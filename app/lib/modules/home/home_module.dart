import 'package:flutter_modular/flutter_modular.dart';
import 'package:organiq/modules/home/data/repositories/home_repository.dart';
import 'package:organiq/modules/home/domain/repositories/i_home_repository.dart';
import 'package:organiq/modules/home/domain/usecases/get_home_dashboard_usecase.dart';
import 'package:organiq/shared/services/cache/cache_service.dart';
import 'package:organiq/shared/services/connectivity/connectivity_service.dart';
import 'package:organiq/shared/services/http/http_client.dart';

class HomeApiModule {
  static void binds(Injector i) {
    i.addLazySingleton<IHomeRepository>(
      () => HomeRepository(
        i.get<IHttpClient>(),
        i.get<ICacheService>(),
        i.get<IConnectivityService>(),
      ),
    );
    i.addLazySingleton<GetHomeDashboardUsecase>(GetHomeDashboardUsecase.new);
  }
}
