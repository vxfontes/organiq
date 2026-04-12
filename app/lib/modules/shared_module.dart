import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:organiq/modules/app_logs/app_logs_module.dart';
import 'package:organiq/modules/auth/auth_module.dart';
import 'package:organiq/modules/events/events_module.dart';
import 'package:organiq/modules/flags/flags_module.dart';
import 'package:organiq/modules/home/home_module.dart';
import 'package:organiq/modules/inbox/inbox_module.dart';
import 'package:organiq/modules/notifications/notifications_module.dart';
import 'package:organiq/modules/reminders/reminders_module.dart';
import 'package:organiq/modules/routines/routines_module.dart';
import 'package:organiq/modules/shopping/shopping_module.dart';
import 'package:organiq/modules/splash/splash_module.dart';
import 'package:organiq/modules/suggestions/suggestions_module.dart';
import 'package:organiq/modules/tasks/tasks_module.dart';
import 'package:organiq/shared/services/analytics/app_error_log_service.dart';
import 'package:organiq/shared/services/analytics/app_monitoring_service.dart';
import 'package:organiq/shared/services/analytics/app_session_service.dart';
import 'package:organiq/shared/services/app_config/app_config_service.dart';
import 'package:organiq/shared/services/analytics/screen_log_service.dart';
import 'package:organiq/shared/services/cache/cache_service.dart';
import 'package:organiq/shared/services/connectivity/connectivity_service.dart';
import 'package:organiq/shared/services/http/dio_http_client.dart';
import 'package:organiq/shared/services/http/http_client.dart';
import 'package:organiq/shared/services/speech/speech_transcription_service.dart';
import 'package:organiq/shared/storage/app_preferences.dart';
import 'package:organiq/shared/storage/auth_token_store.dart';
import 'package:organiq/shared/storage/token_storage.dart';

// SharedModule usa AppPreferences.instance para acessar SharedPreferences.
// A instância é inicializada em main() antes do runApp, garantindo que está
// disponível quando qualquer módulo for resolvido pelo container de DI.
class SharedModule extends Module {

  @override
  void exportedBinds(i) {
    i.addLazySingleton<TokenStorage>(TokenStorage.new);
    i.addLazySingleton<AuthTokenStore>(
      () => AuthTokenStore(i.get<TokenStorage>()),
    );
    i.addLazySingleton<AppMonitoringService>(
      () => AppMonitoringService.instance,
    );
    i.addLazySingleton<IHttpClient>(
      () {
        const profileStr = String.fromEnvironment(
          'APP_PROFILE',
          defaultValue: 'prd',
        );
        const profile = profileStr == 'dev' ? Profile.DEV : Profile.PRD;
        return DioHttpClient(
          profile,
          tokenStore: i.get<AuthTokenStore>(),
          monitoringService: i.get<AppMonitoringService>(),
          cacheService: i.get<ICacheService>(),
        );
      },
    );
    i.addLazySingleton<IAppConfigService>(AppConfigService.new);
    i.addLazySingleton<AppSessionService>(AppSessionService.new);
    i.addLazySingleton<AppErrorLogService>(AppErrorLogService.new);
    i.addLazySingleton<ScreenLogService>(ScreenLogService.new);
    i.addLazySingleton<ISpeechTranscriptionService>(
      SpeechTranscriptionService.new,
    );

    // Cache e conectividade — singletons globais compartilhados por todos os
    // módulos. Registrar aqui garante uma única instância de SharedPreferences
    // e Connectivity no grafo de dependências.
    i.addLazySingleton<ICacheService>(() => CacheService(AppPreferences.instance));
    i.addLazySingleton<IConnectivityService>(
      () => ConnectivityService(Connectivity()),
    );

    // modules
    AppLogsModule.binds(i);
    AuthModule.binds(i);
    EventsModule.binds(i);
    FlagsModule.binds(i);
    HomeApiModule.binds(i);
    InboxModule.binds(i);
    NotificationsModule.binds(i);
    RemindersModule.binds(i);
    RoutinesModule.binds(i);
    ShoppingModule.binds(i);
    SplashModule.binds(i);
    SuggestionsModule.binds(i);
    TasksModule.binds(i);
  }
}
