import 'package:dartz/dartz.dart';
import 'package:organiq/modules/notifications/data/models/notification_log_model.dart';
import 'package:organiq/modules/notifications/domain/repositories/i_notifications_repository.dart';
import 'package:organiq/shared/errors/api_error_mapper.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/services/cache/cache_service.dart';
import 'package:organiq/shared/services/connectivity/connectivity_service.dart';
import 'package:organiq/shared/services/http/app_path.dart';
import 'package:organiq/shared/services/http/http_client.dart';

const _cacheKeyNotifications = 'cache:${AppPath.notifications}';
const _notificationsTtl = Duration(minutes: 2);

class NotificationsRepository implements INotificationsRepository {
  NotificationsRepository(this._httpClient, this._cache, this._connectivity);

  final IHttpClient _httpClient;
  final ICacheService _cache;
  final IConnectivityService _connectivity;

  // -------------------------------------------------------------------------
  // fetchNotifications — estratégia cache-first com TTL de 2min
  //
  // Notificações têm dado dinâmico; TTL curto equilibra frescor e performance.
  // Usa offset em vez de cursor — sem cursor, não há distinção de paginação
  // pelo mesmo critério; cacheamos apenas a chamada sem offset (primeira página).
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, List<NotificationLogModel>>> fetchNotifications({
    int? limit,
    int? offset,
  }) async {
    // Apenas cacheia a primeira página (sem offset ou offset == 0).
    final isFirstPage = offset == null || offset == 0;

    if (isFirstPage) {
      final cached = await _cache.get(_cacheKeyNotifications);
      if (cached != null) {
        try {
          final List items = cached['items'] ?? [];
          return Right(
            items.map((e) => NotificationLogModel.fromMap(e)).toList(),
          );
        } catch (_) {
          await _cache.invalidate(_cacheKeyNotifications);
        }
      }

      final online = await _connectivity.isOnline();
      if (!online) {
        return Left(
          NetworkFailure(
            message:
                'Sem conexão. Conecte-se à internet para carregar suas notificações.',
          ),
        );
      }
    }

    return _fetchNotificationsFromApi(limit: limit, offset: offset);
  }

  Future<Either<Failure, List<NotificationLogModel>>>
      _fetchNotificationsFromApi({
    int? limit,
    int? offset,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (limit != null) query['limit'] = limit;
      if (offset != null) query['offset'] = offset;

      final response = await _httpClient.get(
        AppPath.notifications,
        queryParameters: query,
      );
      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 200 && statusCode < 300) {
        final isFirstPage = offset == null || offset == 0;
        if (isFirstPage && response.data is Map<String, dynamic>) {
          await _cache.set(
            _cacheKeyNotifications,
            response.data as Map<String, dynamic>,
            ttl: _notificationsTtl,
          );
        }
        final List items = response.data['items'] ?? [];
        return Right(
          items.map((e) => NotificationLogModel.fromMap(e)).toList(),
        );
      }
      return Left(
        GetListFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao carregar notificações.',
          ),
        ),
      );
    } catch (e) {
      return Left(GetListFailure(message: e.toString()));
    }
  }

  // -------------------------------------------------------------------------
  // markAsRead — invalida cache de notificações após sucesso
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, Unit>> markAsRead(String id) async {
    try {
      final response = await _httpClient.patch(AppPath.notificationRead(id));
      if ((response.statusCode ?? 0) < 300) {
        await _cache.invalidate(_cacheKeyNotifications);
        return const Right(unit);
      }
      return Left(
        UpdateFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao marcar como lida.',
          ),
        ),
      );
    } catch (e) {
      return Left(UpdateFailure(message: e.toString()));
    }
  }

  // -------------------------------------------------------------------------
  // markAllAsRead — invalida cache de notificações após sucesso
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, Unit>> markAllAsRead() async {
    try {
      final response = await _httpClient.patch(AppPath.notificationsReadAll);
      if ((response.statusCode ?? 0) < 300) {
        await _cache.invalidate(_cacheKeyNotifications);
        return const Right(unit);
      }
      return Left(
        UpdateFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao marcar todas como lidas.',
          ),
        ),
      );
    } catch (e) {
      return Left(UpdateFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> registerDeviceToken(
    String deviceId,
    String pushToken,
    String platform, {
    String? deviceName,
    String? appVersion,
  }) async {
    try {
      final response = await _httpClient.post(
        AppPath.deviceToken,
        data: {
          'deviceId': deviceId,
          'pushToken': pushToken,
          'platform': platform,
          'deviceName': deviceName,
          'appVersion': appVersion,
        },
      );
      if ((response.statusCode ?? 0) < 300) {
        return const Right(unit);
      }
      return Left(
        SaveFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao registrar dispositivo.',
          ),
        ),
      );
    } catch (e) {
      return Left(SaveFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> unregisterDeviceToken(String deviceId) async {
    try {
      final response = await _httpClient.delete(
        AppPath.deviceToken,
        data: {'deviceId': deviceId},
      );
      if ((response.statusCode ?? 0) < 300) return const Right(unit);
      return Left(
        DeleteFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao remover dispositivo.',
          ),
        ),
      );
    } catch (e) {
      return Left(DeleteFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendTestNotification() async {
    try {
      final response = await _httpClient.post(AppPath.notificationTest);
      if ((response.statusCode ?? 0) < 300) return const Right(unit);
      return Left(
        SaveFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao enviar teste.',
          ),
        ),
      );
    } catch (e) {
      return Left(SaveFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendTestEmailDigest() async {
    try {
      final response = await _httpClient.post(AppPath.digestTest);
      if ((response.statusCode ?? 0) < 300) return const Right(unit);
      return Left(
        SaveFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao enviar e-mail de teste.',
          ),
        ),
      );
    } catch (e) {
      return Left(SaveFailure(message: e.toString()));
    }
  }
}
