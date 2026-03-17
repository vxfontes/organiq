import 'package:organiq/modules/auth/data/models/auth_login_input.dart';
import 'package:organiq/modules/auth/data/models/auth_session_output.dart';
import 'package:organiq/modules/auth/data/models/auth_signup_input.dart';
import 'package:organiq/modules/auth/data/models/auth_user_model.dart';
import 'package:dartz/dartz.dart';
import 'package:organiq/shared/errors/failures.dart';

abstract class IAuthRepository {
  Future<Either<Failure, AuthSessionOutput>> login(AuthLoginInput input);
  Future<Either<Failure, AuthSessionOutput>> signup(AuthSignupInput input);
  Future<Either<Failure, AuthUserModel>> me();
  Future<Either<Failure, void>> logout();
}
