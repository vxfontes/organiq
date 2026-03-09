import 'package:dartz/dartz.dart';
import 'package:inbota/modules/notifications/domain/repositories/i_notifications_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

class MarkNotificationAsReadUsecase extends IBUsecase {
  final INotificationsRepository repository;

  MarkNotificationAsReadUsecase(this.repository);

  UsecaseResponse<Failure, Unit> call(String id) {
    return repository.markAsRead(id);
  }
}
