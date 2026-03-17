import 'package:dartz/dartz.dart';
import 'package:organiq/modules/notifications/domain/repositories/i_notifications_repository.dart';
import 'package:organiq/shared/errors/failures.dart';

class SendTestNotificationUsecase {
  final INotificationsRepository repository;
  SendTestNotificationUsecase(this.repository);

  Future<Either<Failure, Unit>> call() {
    return repository.sendTestNotification();
  }
}
