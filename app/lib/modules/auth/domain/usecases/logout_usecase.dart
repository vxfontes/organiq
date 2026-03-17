import 'package:organiq/modules/auth/domain/repositories/i_auth_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/services/push/push_notification_service.dart';
import 'package:organiq/shared/templates/oq_usecase.dart';

class LogoutUsecase extends OQUsecase {
  final IAuthRepository _repository;

  LogoutUsecase(this._repository);

  UsecaseResponse<Failure, void> call() async {
    await PushNotificationService.instance.unregisterDevice();
    return _repository.logout();
  }
}
