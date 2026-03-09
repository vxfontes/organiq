import 'package:dartz/dartz.dart';
import 'package:inbota/modules/notifications/data/models/notification_preferences_model.dart';
import 'package:inbota/shared/errors/failures.dart';

abstract class INotificationPrefsRepository {
  Future<Either<Failure, NotificationPreferencesModel>> getPreferences();
  Future<Either<Failure, NotificationPreferencesModel>> updatePreferences(NotificationPreferencesModel prefs);
}
