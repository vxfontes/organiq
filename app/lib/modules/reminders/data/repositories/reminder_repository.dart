import 'package:dartz/dartz.dart';

import 'package:organiq/modules/reminders/data/models/reminder_list_output.dart';
import 'package:organiq/modules/reminders/data/models/reminder_output.dart';
import 'package:organiq/modules/reminders/data/models/reminder_create_input.dart';
import 'package:organiq/modules/reminders/data/models/reminder_update_input.dart';
import 'package:organiq/modules/reminders/domain/repositories/i_reminder_repository.dart';
import 'package:organiq/shared/errors/api_error_mapper.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/services/http/app_path.dart';
import 'package:organiq/shared/services/http/http_client.dart';

class ReminderRepository implements IReminderRepository {
  ReminderRepository(this._httpClient);

  final IHttpClient _httpClient;
  @override
  Future<Either<Failure, ReminderListOutput>> fetchReminders({
    int? limit,
    String? cursor,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (limit != null) query['limit'] = limit;
      if (cursor != null) query['cursor'] = cursor;

      final response = await _httpClient.get(
        AppPath.reminders,
        queryParameters: query.isEmpty ? null : query,
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        final data = _asMap(response.data);
        return Right(ReminderListOutput.fromJson(data));
      }

      return Left(
        GetListFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao carregar lembretes.',
          ),
        ),
      );
    } catch (err) {
      return Left(GetListFailure(message: err.toString()));
    }
  }

  @override
  Future<Either<Failure, ReminderOutput>> createReminder(
    ReminderCreateInput input,
  ) async {
    try {
      final response = await _httpClient.post(
        AppPath.reminders,
        data: input.toJson(),
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        return Right(ReminderOutput.fromJson(_asMap(response.data)));
      }

      return Left(
        SaveFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao criar lembrete.',
          ),
        ),
      );
    } catch (err) {
      return Left(SaveFailure(message: err.toString()));
    }
  }

  @override
  Future<Either<Failure, ReminderOutput>> updateReminder(
    ReminderUpdateInput input,
  ) async {
    try {
      final response = await _httpClient.patch(
        AppPath.reminderById(input.id),
        data: input.toJson(),
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        return Right(ReminderOutput.fromJson(_asMap(response.data)));
      }

      return Left(
        UpdateFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao carregar lembretes.',
          ),
        ),
      );
    } catch (err) {
      return Left(UpdateFailure(message: err.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteReminder(String id) async {
    try {
      final response = await _httpClient.delete(AppPath.reminderById(id));

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        return const Right(unit);
      }

      return Left(
        DeleteFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao excluir lembrete.',
          ),
        ),
      );
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
