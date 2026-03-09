import 'package:inbota/modules/notifications/data/models/notification_log_model.dart';
import 'package:inbota/modules/notifications/domain/repositories/i_notifications_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

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
