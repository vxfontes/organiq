import 'package:organiq/modules/auth/data/models/auth_login_input.dart';
import 'package:organiq/modules/auth/data/models/auth_session_output.dart';
import 'package:organiq/modules/auth/domain/repositories/i_auth_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/ib_usecase.dart';

class LoginUsecase extends IBUsecase {
  final IAuthRepository _repository;

  LoginUsecase(this._repository);

  UsecaseResponse<Failure, AuthSessionOutput> call(AuthLoginInput input) {
    return _repository.login(input);
  }
}
