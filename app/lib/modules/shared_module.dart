import 'package:flutter_modular/flutter_modular.dart';
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
import 'package:organiq/modules/tasks/tasks_module.dart';
import 'package:organiq/shared/services/http/dio_http_client.dart';
import 'package:organiq/shared/services/http/http_client.dart';
import 'package:organiq/shared/services/speech/speech_transcription_service.dart';
import 'package:organiq/shared/storage/auth_token_store.dart';
import 'package:organiq/shared/storage/token_storage.dart';

class SharedModule extends Module {
  @override
  void exportedBinds(i) {
    i.addLazySingleton<TokenStorage>(TokenStorage.new);
    i.addLazySingleton<AuthTokenStore>(
      () => AuthTokenStore(i.get<TokenStorage>()),
    );
    i.addLazySingleton<IHttpClient>(
      () => DioHttpClient(Profile.DEV, tokenStore: i.get<AuthTokenStore>()),
    );
    i.addLazySingleton<ISpeechTranscriptionService>(
      SpeechTranscriptionService.new,
    );

    // modules
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
    TasksModule.binds(i);
  }
}
