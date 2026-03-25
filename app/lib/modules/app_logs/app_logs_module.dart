import 'package:flutter_modular/flutter_modular.dart';
import 'package:organiq/modules/app_logs/data/repositories/app_error_log_repository.dart';
import 'package:organiq/modules/app_logs/data/repositories/app_screen_log_repository.dart';
import 'package:organiq/modules/app_logs/domain/repositories/i_app_error_log_repository.dart';
import 'package:organiq/modules/app_logs/domain/repositories/i_app_screen_log_repository.dart';
import 'package:organiq/modules/app_logs/domain/usecases/log_app_error_usecase.dart';
import 'package:organiq/modules/app_logs/domain/usecases/log_screen_usecase.dart';
import 'package:organiq/shared/services/http/app_log_http_client.dart';

class AppLogsModule {
  static void binds(Injector i) {
    i.addLazySingleton<AppLogHttpClient>(AppLogHttpClient.new);
    i.addLazySingleton<IAppErrorLogRepository>(AppErrorLogRepository.new);
    i.addLazySingleton<IAppScreenLogRepository>(AppScreenLogRepository.new);
    i.addLazySingleton<LogAppErrorUsecase>(LogAppErrorUsecase.new);
    i.addLazySingleton<LogScreenUsecase>(LogScreenUsecase.new);
  }
}
