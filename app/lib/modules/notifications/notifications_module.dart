import 'package:flutter_modular/flutter_modular.dart';
import 'package:inbota/modules/notifications/data/repositories/notification_prefs_repository.dart';
import 'package:inbota/modules/notifications/data/repositories/notifications_repository.dart';
import 'package:inbota/modules/notifications/domain/repositories/i_notification_prefs_repository.dart';
import 'package:inbota/modules/notifications/domain/repositories/i_notifications_repository.dart';
import 'package:inbota/modules/notifications/domain/usecases/get_notification_prefs_usecase.dart';
import 'package:inbota/modules/notifications/domain/usecases/send_test_notification_usecase.dart';
import 'package:inbota/modules/notifications/domain/usecases/update_notification_prefs_usecase.dart';

class NotificationsModule {
  static void binds(Injector i) {
    // repositories
    i.addLazySingleton<INotificationPrefsRepository>(NotificationPrefsRepository.new);
    i.addLazySingleton<INotificationsRepository>(NotificationsRepository.new);

    // usecases
    i.addLazySingleton<GetNotificationPrefsUsecase>(GetNotificationPrefsUsecase.new);
    i.addLazySingleton<UpdateNotificationPrefsUsecase>(UpdateNotificationPrefsUsecase.new);
    i.addLazySingleton<SendTestNotificationUsecase>(SendTestNotificationUsecase.new);
  }
}
