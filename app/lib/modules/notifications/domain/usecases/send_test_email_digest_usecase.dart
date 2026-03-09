import 'package:dartz/dartz.dart';
import 'package:inbota/modules/notifications/domain/repositories/i_notifications_repository.dart';
import 'package:inbota/shared/errors/failures.dart';

class SendTestEmailDigestUsecase {
  final INotificationsRepository repository;
  SendTestEmailDigestUsecase(this.repository);

  Future<Either<Failure, Unit>> call() {
    return repository.sendTestEmailDigest();
  }
}
