import 'package:organiq/modules/auth/data/models/auth_session_output.dart';
import 'package:organiq/modules/auth/data/models/auth_signup_input.dart';
import 'package:organiq/modules/auth/domain/repositories/i_auth_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/oq_usecase.dart';

class SignupUsecase extends OQUsecase {
  final IAuthRepository _repository;

  SignupUsecase(this._repository);

  UsecaseResponse<Failure, AuthSessionOutput> call(AuthSignupInput input) {
    return _repository.signup(input);
  }
}
