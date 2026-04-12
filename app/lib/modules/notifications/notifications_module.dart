import 'package:flutter_modular/flutter_modular.dart';
import 'package:organiq/modules/notifications/data/repositories/notification_prefs_repository.dart';
import 'package:organiq/modules/notifications/data/repositories/notifications_repository.dart';
import 'package:organiq/modules/notifications/domain/repositories/i_notification_prefs_repository.dart';
import 'package:organiq/modules/notifications/domain/repositories/i_notifications_repository.dart';
import 'package:organiq/modules/notifications/domain/usecases/get_notification_prefs_usecase.dart';
import 'package:organiq/modules/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:organiq/modules/notifications/domain/usecases/mark_all_notifications_as_read_usecase.dart';
import 'package:organiq/modules/notifications/domain/usecases/mark_notification_as_read_usecase.dart';
import 'package:organiq/modules/notifications/domain/usecases/send_test_email_digest_usecase.dart';
import 'package:organiq/modules/notifications/domain/usecases/send_test_notification_usecase.dart';
import 'package:organiq/modules/notifications/domain/usecases/update_notification_prefs_usecase.dart';
import 'package:organiq/shared/services/cache/cache_service.dart';
import 'package:organiq/shared/services/connectivity/connectivity_service.dart';
import 'package:organiq/shared/services/http/http_client.dart';

class NotificationsModule {
  static void binds(Injector i) {
    // repositories
    i.addLazySingleton<INotificationPrefsRepository>(
      () => NotificationPrefsRepository(
        i.get<IHttpClient>(),
        i.get<ICacheService>(),
        i.get<IConnectivityService>(),
      ),
    );
    i.addLazySingleton<INotificationsRepository>(
      () => NotificationsRepository(
        i.get<IHttpClient>(),
        i.get<ICacheService>(),
        i.get<IConnectivityService>(),
      ),
    );

    // usecases
    i.addLazySingleton<GetNotificationPrefsUsecase>(
      GetNotificationPrefsUsecase.new,
    );
    i.addLazySingleton<UpdateNotificationPrefsUsecase>(
      UpdateNotificationPrefsUsecase.new,
    );
    i.addLazySingleton<SendTestNotificationUsecase>(
      SendTestNotificationUsecase.new,
    );
    i.addLazySingleton<SendTestEmailDigestUsecase>(
      SendTestEmailDigestUsecase.new,
    );
    i.addLazySingleton<GetNotificationsUsecase>(GetNotificationsUsecase.new);
    i.addLazySingleton<MarkNotificationAsReadUsecase>(
      MarkNotificationAsReadUsecase.new,
    );
    i.addLazySingleton<MarkAllNotificationsAsReadUsecase>(
      MarkAllNotificationsAsReadUsecase.new,
    );
  }
}
