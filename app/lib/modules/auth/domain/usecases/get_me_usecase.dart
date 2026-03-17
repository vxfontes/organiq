import 'package:organiq/modules/auth/data/models/auth_user_model.dart';
import 'package:organiq/modules/auth/domain/repositories/i_auth_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/oq_usecase.dart';

class GetMeUsecase extends OQUsecase {
  final IAuthRepository _repository;

  GetMeUsecase(this._repository);

  UsecaseResponse<Failure, AuthUserModel> call() {
    return _repository.me();
  }
}
