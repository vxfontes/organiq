import 'package:dartz/dartz.dart';
import 'package:organiq/modules/notifications/data/models/notification_log_model.dart';
import 'package:organiq/shared/errors/failures.dart';

abstract class INotificationsRepository {
  Future<Either<Failure, List<NotificationLogModel>>> fetchNotifications({int? limit, int? offset});
  Future<Either<Failure, Unit>> markAsRead(String id);
  Future<Either<Failure, Unit>> markAllAsRead();
  Future<Either<Failure, String>> registerDeviceToken(String deviceId, String platform, {String? deviceName, String? appVersion});
  Future<Either<Failure, Unit>> unregisterDeviceToken(String deviceId);
  Future<Either<Failure, Unit>> sendTestNotification();
  Future<Either<Failure, Unit>> sendTestEmailDigest();
}
