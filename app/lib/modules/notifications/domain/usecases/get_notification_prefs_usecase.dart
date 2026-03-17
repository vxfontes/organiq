import 'package:dartz/dartz.dart';
import 'package:organiq/modules/notifications/data/models/notification_preferences_model.dart';
import 'package:organiq/modules/notifications/domain/repositories/i_notification_prefs_repository.dart';
import 'package:organiq/shared/errors/failures.dart';

class GetNotificationPrefsUsecase {
  final INotificationPrefsRepository repository;
  GetNotificationPrefsUsecase(this.repository);

  Future<Either<Failure, NotificationPreferencesModel>> call() {
    return repository.getPreferences();
  }
}
