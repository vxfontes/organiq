import 'package:dartz/dartz.dart';
import 'package:organiq/modules/auth/data/models/auth_login_input.dart';
import 'package:organiq/modules/auth/data/models/auth_session_output.dart';
import 'package:organiq/modules/auth/data/models/auth_signup_input.dart';
import 'package:organiq/modules/auth/data/models/auth_user_model.dart';
import 'package:organiq/modules/auth/domain/repositories/i_auth_repository.dart';
import 'package:organiq/shared/errors/api_error_mapper.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/services/analytics/app_session_service.dart';
import 'package:organiq/shared/services/http/app_path.dart';
import 'package:organiq/shared/services/http/http_client.dart';
import 'package:organiq/shared/storage/auth_token_store.dart';

class AuthRepository implements IAuthRepository {
  final IHttpClient _httpClient;
  final AuthTokenStore _tokenStore;
  final AppSessionService _sessionService;

  AuthRepository(this._httpClient, this._tokenStore, this._sessionService);

  @override
  Future<Either<Failure, AuthSessionOutput>> login(AuthLoginInput input) async {
    try {
      final response = await _httpClient.post(
        AppPath.authLogin,
        data: input.toJson(),
        extra: const {'auth': false},
      );
      final statusCode = response.statusCode ?? 0;

      if (_isSuccess(statusCode)) {
        final session = AuthSessionOutput.fromJson(_asMap(response.data));
        if (session.token.isEmpty) {
          return Left(GetFailure(message: 'Token inválido'));
        }
        await _sessionService.refreshSession();
        await _tokenStore.saveToken(session.token);
        return Right(session);
      }

      return Left(
        GetFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro inesperado',
          ),
        ),
      );
    } catch (err) {
      return Left(GetFailure(message: err.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthSessionOutput>> signup(
    AuthSignupInput input,
  ) async {
    try {
      final response = await _httpClient.post(
        AppPath.authSignup,
        data: input.toJson(),
        extra: const {'auth': false},
      );
      final statusCode = response.statusCode ?? 0;

      if (_isSuccess(statusCode)) {
        final session = AuthSessionOutput.fromJson(_asMap(response.data));
        if (session.token.isEmpty) {
          return Left(SaveFailure(message: 'Token inválido'));
        }
        await _sessionService.refreshSession();
        await _tokenStore.saveToken(session.token);
        return Right(session);
      }

      return Left(
        SaveFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro inesperado',
          ),
        ),
      );
    } catch (err) {
      return Left(SaveFailure(message: err.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUserModel>> me() async {
    try {
      final response = await _httpClient.get(AppPath.me);
      final statusCode = response.statusCode ?? 0;

      if (_isSuccess(statusCode)) {
        final session = AuthSessionOutput.fromJson(_asMap(response.data));
        return Right(session.user);
      }

      return Left(
        GetFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro inesperado',
          ),
        ),
      );
    } catch (err) {
      return Left(GetFailure(message: err.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _tokenStore.clearToken();
      await _sessionService.refreshSession();
      return const Right(null);
    } catch (err) {
      return Left(DeleteFailure(message: err.toString()));
    }
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}
