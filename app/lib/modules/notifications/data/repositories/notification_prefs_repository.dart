import 'package:dartz/dartz.dart';
import 'package:organiq/modules/notifications/data/models/notification_preferences_model.dart';
import 'package:organiq/modules/notifications/domain/repositories/i_notification_prefs_repository.dart';
import 'package:organiq/shared/errors/api_error_mapper.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/services/cache/cache_service.dart';
import 'package:organiq/shared/services/connectivity/connectivity_service.dart';
import 'package:organiq/shared/services/http/app_path.dart';
import 'package:organiq/shared/services/http/http_client.dart';

const _cacheKeyPrefs = 'cache:${AppPath.notificationPreferences}';
const _prefsTtl = Duration(minutes: 10);

class NotificationPrefsRepository implements INotificationPrefsRepository {
  NotificationPrefsRepository(this._httpClient, this._cache, this._connectivity);

  final IHttpClient _httpClient;
  final ICacheService _cache;
  final IConnectivityService _connectivity;

  // -------------------------------------------------------------------------
  // getPreferences — estratégia cache-first com TTL de 10min
  //
  // Preferências de notificação mudam raramente; TTL de 10min é adequado.
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, NotificationPreferencesModel>> getPreferences() async {
    final cached = await _cache.get(_cacheKeyPrefs);
    if (cached != null) {
      try {
        return Right(NotificationPreferencesModel.fromMap(cached));
      } catch (_) {
        await _cache.invalidate(_cacheKeyPrefs);
      }
    }

    final online = await _connectivity.isOnline();
    if (!online) {
      return Left(
        NetworkFailure(
          message:
              'Sem conexão. Conecte-se à internet para carregar suas preferências.',
        ),
      );
    }

    return _fetchPreferencesFromApi();
  }

  Future<Either<Failure, NotificationPreferencesModel>>
      _fetchPreferencesFromApi() async {
    try {
      final response = await _httpClient.get(AppPath.notificationPreferences);
      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 200 && statusCode < 300) {
        if (response.data is Map<String, dynamic>) {
          await _cache.set(
            _cacheKeyPrefs,
            response.data as Map<String, dynamic>,
            ttl: _prefsTtl,
          );
        }
        return Right(NotificationPreferencesModel.fromMap(response.data));
      }
      return Left(
        GetFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao carregar preferências.',
          ),
        ),
      );
    } catch (e) {
      return Left(GetFailure(message: e.toString()));
    }
  }

  // -------------------------------------------------------------------------
  // updatePreferences — invalida cache após sucesso
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, NotificationPreferencesModel>> updatePreferences(
    NotificationPreferencesModel prefs,
  ) async {
    try {
      final response = await _httpClient.put(
        AppPath.notificationPreferences,
        data: prefs.toMap(),
      );
      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 200 && statusCode < 300) {
        await _cache.invalidate(_cacheKeyPrefs);
        return Right(NotificationPreferencesModel.fromMap(response.data));
      }
      return Left(
        UpdateFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao atualizar preferências.',
          ),
        ),
      );
    } catch (e) {
      return Left(UpdateFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, String>>> getDailySummaryToken() async {
    try {
      final response = await _httpClient.get(AppPath.dailySummaryToken);
      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 200 && statusCode < 300) {
        return Right({
          'token': response.data['token'] as String? ?? '',
          'url': response.data['url'] as String? ?? '',
        });
      }
      return Left(
        GetFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao carregar token.',
          ),
        ),
      );
    } catch (e) {
      return Left(GetFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, String>>> rotateDailySummaryToken() async {
    try {
      final response = await _httpClient.post(AppPath.dailySummaryTokenRotate);
      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 200 && statusCode < 300) {
        return Right({
          'token': response.data['token'] as String? ?? '',
          'url': response.data['url'] as String? ?? '',
        });
      }
      return Left(
        UpdateFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao rotacionar token.',
          ),
        ),
      );
    } catch (e) {
      return Left(UpdateFailure(message: e.toString()));
    }
  }
}
