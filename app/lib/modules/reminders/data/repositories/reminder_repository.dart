import 'package:dartz/dartz.dart';

import 'package:organiq/modules/reminders/data/models/reminder_list_output.dart';
import 'package:organiq/modules/reminders/data/models/reminder_output.dart';
import 'package:organiq/modules/reminders/data/models/reminder_create_input.dart';
import 'package:organiq/modules/reminders/data/models/reminder_update_input.dart';
import 'package:organiq/modules/reminders/domain/repositories/i_reminder_repository.dart';
import 'package:organiq/shared/errors/api_error_mapper.dart';
import 'package:organiq/shared/errors/exception_mapper.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/extensions/response_model_extensions.dart';
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

      if (response.isSuccess) {
        return Right(ReminderListOutput.fromJson(response.asMap()));
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
      return Left(
        ExceptionMapper.toFailure(
          err,
          fallbackMessage: 'Erro ao carregar lembretes.',
          failureFactory: (msg) => GetListFailure(message: msg),
        ),
      );
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

      if (response.isSuccess) {
        return Right(ReminderOutput.fromJson(response.asMap()));
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
      return Left(
        ExceptionMapper.toFailure(
          err,
          fallbackMessage: 'Erro ao criar lembrete.',
          failureFactory: (msg) => SaveFailure(message: msg),
        ),
      );
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

      if (response.isSuccess) {
        return Right(ReminderOutput.fromJson(response.asMap()));
      }

      return Left(
        UpdateFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao atualizar lembrete.',
          ),
        ),
      );
    } catch (err) {
      return Left(
        ExceptionMapper.toFailure(
          err,
          fallbackMessage: 'Erro ao atualizar lembrete.',
          failureFactory: (msg) => UpdateFailure(message: msg),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteReminder(String id) async {
    try {
      final response = await _httpClient.delete(AppPath.reminderById(id));

      if (response.isSuccess) {
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
      return Left(
        ExceptionMapper.toFailure(
          err,
          fallbackMessage: 'Erro ao excluir lembrete.',
          failureFactory: (msg) => DeleteFailure(message: msg),
        ),
      );
    }
  }
}
