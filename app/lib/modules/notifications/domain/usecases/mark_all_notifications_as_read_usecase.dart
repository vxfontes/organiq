import 'package:dartz/dartz.dart';
import 'package:inbota/modules/notifications/domain/repositories/i_notifications_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

class MarkAllNotificationsAsReadUsecase extends IBUsecase {
  final INotificationsRepository repository;

  MarkAllNotificationsAsReadUsecase(this.repository);

  UsecaseResponse<Failure, Unit> call() {
    return repository.markAllAsRead();
  }
}
