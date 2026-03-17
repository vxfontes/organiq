import 'package:organiq/modules/notifications/data/models/notification_log_model.dart';
import 'package:organiq/modules/notifications/domain/repositories/i_notifications_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/ib_usecase.dart';

class GetNotificationsUsecase extends IBUsecase {
  final INotificationsRepository repository;

  GetNotificationsUsecase(this.repository);

  UsecaseResponse<Failure, List<NotificationLogModel>> call({
    int? limit,
    int? offset,
  }) {
    return repository.fetchNotifications(limit: limit, offset: offset);
  }
}
