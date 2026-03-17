import 'package:dartz/dartz.dart';
import 'package:organiq/modules/notifications/domain/repositories/i_notifications_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/ib_usecase.dart';

class MarkNotificationAsReadUsecase extends IBUsecase {
  final INotificationsRepository repository;

  MarkNotificationAsReadUsecase(this.repository);

  UsecaseResponse<Failure, Unit> call(String id) {
    return repository.markAsRead(id);
  }
}
