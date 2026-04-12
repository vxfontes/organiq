import 'package:dartz/dartz.dart';
import 'package:organiq/modules/auth/data/models/auth_login_input.dart';
import 'package:organiq/modules/auth/data/models/auth_session_output.dart';
import 'package:organiq/modules/auth/data/models/auth_signup_input.dart';
import 'package:organiq/modules/auth/data/models/auth_user_model.dart';
import 'package:organiq/modules/auth/domain/repositories/i_auth_repository.dart';
import 'package:organiq/shared/errors/api_error_mapper.dart';
import 'package:organiq/shared/errors/exception_mapper.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/extensions/response_model_extensions.dart';
import 'package:organiq/shared/services/analytics/app_session_service.dart';
import 'package:organiq/shared/services/cache/cache_service.dart';
import 'package:organiq/shared/services/http/app_path.dart';
import 'package:organiq/shared/services/http/http_client.dart';
import 'package:organiq/shared/storage/auth_token_store.dart';

class AuthRepository implements IAuthRepository {
  final IHttpClient _httpClient;
  final AuthTokenStore _tokenStore;
  final AppSessionService _sessionService;
  final ICacheService _cache;

  AuthRepository(this._httpClient, this._tokenStore, this._sessionService, this._cache);

  @override
  Future<Either<Failure, AuthSessionOutput>> login(AuthLoginInput input) async {
    try {
      final response = await _httpClient.post(
        AppPath.authLogin,
        data: input.toJson(),
        extra: const {'auth': false},
      );

      if (response.isSuccess) {
        final session = AuthSessionOutput.fromJson(response.asMap());
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
      return Left(
        ExceptionMapper.toFailure(
          err,
          fallbackMessage: 'Erro ao fazer login. Tente novamente.',
          failureFactory: (msg) => GetFailure(message: msg),
        ),
      );
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

      if (response.isSuccess) {
        final session = AuthSessionOutput.fromJson(response.asMap());
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
      return Left(
        ExceptionMapper.toFailure(
          err,
          fallbackMessage: 'Erro ao criar conta. Tente novamente.',
          failureFactory: (msg) => SaveFailure(message: msg),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, AuthUserModel>> me() async {
    try {
      final response = await _httpClient.get(AppPath.me);

      if (response.isSuccess) {
        final session = AuthSessionOutput.fromJson(response.asMap());
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
      return Left(
        ExceptionMapper.toFailure(
          err,
          fallbackMessage: 'Erro ao carregar perfil. Tente novamente.',
          failureFactory: (msg) => GetFailure(message: msg),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await Future.wait([
        _tokenStore.clearToken(),
        _cache.clear(),
      ]);
      await _sessionService.refreshSession();
      return const Right(null);
    } catch (err) {
      return Left(
        ExceptionMapper.toFailure(
          err,
          fallbackMessage: 'Erro ao sair. Tente novamente.',
          failureFactory: (msg) => DeleteFailure(message: msg),
        ),
      );
    }
  }
}
