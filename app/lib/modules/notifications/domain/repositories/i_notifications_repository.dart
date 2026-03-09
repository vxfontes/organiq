import 'package:dartz/dartz.dart';
import 'package:inbota/modules/notifications/data/models/notification_log_model.dart';
import 'package:inbota/shared/errors/failures.dart';

abstract class INotificationsRepository {
  Future<Either<Failure, List<NotificationLogModel>>> fetchNotifications({int? limit, int? offset});
  Future<Either<Failure, Unit>> markAsRead(String id);
  Future<Either<Failure, Unit>> markAllAsRead();
  Future<Either<Failure, Unit>> registerDeviceToken(String token, String platform, {String? deviceName, String? appVersion});
  Future<Either<Failure, Unit>> unregisterDeviceToken(String token);
  Future<Either<Failure, Unit>> sendTestNotification();
}
