import 'package:dartz/dartz.dart';
import 'package:inbota/modules/notifications/data/models/notification_preferences_model.dart';
import 'package:inbota/modules/notifications/domain/repositories/i_notification_prefs_repository.dart';
import 'package:inbota/shared/errors/api_error_mapper.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/services/http/app_path.dart';
import 'package:inbota/shared/services/http/http_client.dart';

class NotificationPrefsRepository implements INotificationPrefsRepository {
  NotificationPrefsRepository(this._httpClient);

  final IHttpClient _httpClient;

  @override
  Future<Either<Failure, NotificationPreferencesModel>> getPreferences() async {
    try {
      final response = await _httpClient.get(AppPath.notificationPreferences);
      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 200 && statusCode < 300) {
        return Right(NotificationPreferencesModel.fromMap(response.data));
      }
      return Left(GetFailure(message: ApiErrorMapper.fromResponseData(response.data, fallbackMessage: 'Erro ao carregar preferências.')));
    } catch (e) {
      return Left(GetFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, NotificationPreferencesModel>> updatePreferences(NotificationPreferencesModel prefs) async {
    try {
      final response = await _httpClient.put(AppPath.notificationPreferences, data: prefs.toMap());
      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 200 && statusCode < 300) {
        return Right(NotificationPreferencesModel.fromMap(response.data));
      }
      return Left(UpdateFailure(message: ApiErrorMapper.fromResponseData(response.data, fallbackMessage: 'Erro ao atualizar preferências.')));
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
      return Left(GetFailure(message: ApiErrorMapper.fromResponseData(response.data, fallbackMessage: 'Erro ao carregar token.')));
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
      return Left(UpdateFailure(message: ApiErrorMapper.fromResponseData(response.data, fallbackMessage: 'Erro ao rotacionar token.')));
    } catch (e) {
      return Left(UpdateFailure(message: e.toString()));
    }
  }
}
