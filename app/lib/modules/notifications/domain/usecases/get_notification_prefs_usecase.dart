import 'package:dartz/dartz.dart';
import 'package:inbota/modules/notifications/data/models/notification_preferences_model.dart';
import 'package:inbota/modules/notifications/domain/repositories/i_notification_prefs_repository.dart';
import 'package:inbota/shared/errors/failures.dart';

class GetNotificationPrefsUsecase {
  final INotificationPrefsRepository repository;
  GetNotificationPrefsUsecase(this.repository);

  Future<Either<Failure, NotificationPreferencesModel>> call() {
    return repository.getPreferences();
  }
}
