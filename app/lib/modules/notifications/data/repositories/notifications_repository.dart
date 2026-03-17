import 'package:dartz/dartz.dart';
import 'package:organiq/modules/notifications/data/models/notification_log_model.dart';
import 'package:organiq/modules/notifications/domain/repositories/i_notifications_repository.dart';
import 'package:organiq/shared/errors/api_error_mapper.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/services/http/app_path.dart';
import 'package:organiq/shared/services/http/http_client.dart';
import 'package:organiq/shared/services/push/push_notification_service.dart';

class NotificationsRepository implements INotificationsRepository {
  NotificationsRepository(this._httpClient);

  final IHttpClient _httpClient;

  @override
  Future<Either<Failure, List<NotificationLogModel>>> fetchNotifications({int? limit, int? offset}) async {
    try {
      final query = <String, dynamic>{};
      if (limit != null) query['limit'] = limit;
      if (offset != null) query['offset'] = offset;

      final response = await _httpClient.get(AppPath.notifications, queryParameters: query);
      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 200 && statusCode < 300) {
        final List items = response.data['items'] ?? [];
        return Right(items.map((e) => NotificationLogModel.fromMap(e)).toList());
      }
      return Left(GetListFailure(message: ApiErrorMapper.fromResponseData(response.data, fallbackMessage: 'Erro ao carregar notificações.')));
    } catch (e) {
      return Left(GetListFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> markAsRead(String id) async {
    try {
      final response = await _httpClient.patch(AppPath.notificationRead(id));
      if ((response.statusCode ?? 0) < 300) return const Right(unit);
      return Left(UpdateFailure(message: ApiErrorMapper.fromResponseData(response.data, fallbackMessage: 'Erro ao marcar como lida.')));
    } catch (e) {
      return Left(UpdateFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> markAllAsRead() async {
    try {
      final response = await _httpClient.patch(AppPath.notificationsReadAll);
      if ((response.statusCode ?? 0) < 300) return const Right(unit);
      return Left(UpdateFailure(message: ApiErrorMapper.fromResponseData(response.data, fallbackMessage: 'Erro ao marcar todas como lidas.')));
    } catch (e) {
      return Left(UpdateFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> registerDeviceToken(String deviceId, String platform, {String? deviceName, String? appVersion}) async {
    try {
      final response = await _httpClient.post(AppPath.deviceToken, data: {
        'deviceId': deviceId,
        'platform': platform,
        'deviceName': deviceName,
        'appVersion': appVersion,
      });
      if ((response.statusCode ?? 0) < 300) {
        final topic = response.data['topic'] as String;
        PushNotificationService.instance.updateTopicFromServer(topic);
        return Right(topic);
      }
      return Left(SaveFailure(message: ApiErrorMapper.fromResponseData(response.data, fallbackMessage: 'Erro ao registrar dispositivo.')));
    } catch (e) {
      return Left(SaveFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> unregisterDeviceToken(String deviceId) async {
    try {
      final response = await _httpClient.delete(AppPath.deviceToken, data: {
        'deviceId': deviceId,
      });
      if ((response.statusCode ?? 0) < 300) return const Right(unit);
      return Left(DeleteFailure(message: ApiErrorMapper.fromResponseData(response.data, fallbackMessage: 'Erro ao remover dispositivo.')));
    } catch (e) {
      return Left(DeleteFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendTestNotification() async {
    try {
      final response = await _httpClient.post(AppPath.notificationTest);
      if ((response.statusCode ?? 0) < 300) return const Right(unit);
      return Left(SaveFailure(message: ApiErrorMapper.fromResponseData(response.data, fallbackMessage: 'Erro ao enviar teste.')));
    } catch (e) {
      return Left(SaveFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendTestEmailDigest() async {
    try {
      final response = await _httpClient.post(AppPath.digestTest);
      if ((response.statusCode ?? 0) < 300) return const Right(unit);
      return Left(SaveFailure(message: ApiErrorMapper.fromResponseData(response.data, fallbackMessage: 'Erro ao enviar e-mail de teste.')));
    } catch (e) {
      return Left(SaveFailure(message: e.toString()));
    }
  }
}
