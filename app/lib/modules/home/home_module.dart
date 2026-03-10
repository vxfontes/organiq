import 'package:flutter_modular/flutter_modular.dart';
import 'package:inbota/modules/home/data/repositories/home_repository.dart';
import 'package:inbota/modules/home/domain/repositories/i_home_repository.dart';
import 'package:inbota/modules/home/domain/usecases/get_home_dashboard_usecase.dart';

class HomeApiModule {
  static void binds(Injector i) {
    i.addLazySingleton<IHomeRepository>(HomeRepository.new);
    i.addLazySingleton<GetHomeDashboardUsecase>(GetHomeDashboardUsecase.new);
  }
}
