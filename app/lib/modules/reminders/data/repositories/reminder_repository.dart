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
import 'package:organiq/shared/services/cache/cache_service.dart';
import 'package:organiq/shared/services/connectivity/connectivity_service.dart';
import 'package:organiq/shared/services/http/app_path.dart';
import 'package:organiq/shared/services/http/http_client.dart';

const _cacheKeyReminderList = 'cache:${AppPath.reminders}';
const _cacheKeyDashboard = 'cache:${AppPath.homeDashboard}';

class ReminderRepository implements IReminderRepository {
  ReminderRepository(this._httpClient, this._cache, this._connectivity);

  final IHttpClient _httpClient;
  final ICacheService _cache;
  final IConnectivityService _connectivity;

  // -------------------------------------------------------------------------
  // fetchReminders — estratégia cache-first
  //
  // 1. Tem cursor (paginação): vai direto à API.
  // 2. Sem cursor e cache válido: retorna cache.
  // 3. Sem cursor, cache ausente/expirado, offline: retorna NetworkFailure.
  // 4. Sem cursor, cache ausente/expirado, online: busca API, atualiza cache.
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, ReminderListOutput>> fetchReminders({
    int? limit,
    String? cursor,
  }) async {
    if (cursor != null) {
      return _fetchRemindersFromApi(limit: limit, cursor: cursor);
    }

    final cached = await _cache.get(_cacheKeyReminderList);
    if (cached != null) {
      try {
        return Right(ReminderListOutput.fromJson(cached));
      } catch (_) {
        await _cache.invalidate(_cacheKeyReminderList);
      }
    }

    final online = await _connectivity.isOnline();
    if (!online) {
      return Left(
        NetworkFailure(
          message:
              'Sem conexão. Conecte-se à internet para carregar seus lembretes.',
        ),
      );
    }

    return _fetchRemindersFromApi(limit: limit);
  }

  Future<Either<Failure, ReminderListOutput>> _fetchRemindersFromApi({
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
        final output = ReminderListOutput.fromJson(response.asMap());
        if (cursor == null) {
          await _cache.set(_cacheKeyReminderList, response.asMap());
        }
        return Right(output);
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

  // -------------------------------------------------------------------------
  // createReminder — invalida cache após sucesso
  // -------------------------------------------------------------------------
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
        await Future.wait([
          _cache.invalidate(_cacheKeyReminderList),
          _cache.invalidate(_cacheKeyDashboard),
        ]);
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

  // -------------------------------------------------------------------------
  // updateReminder — invalida cache após sucesso
  // -------------------------------------------------------------------------
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
        await Future.wait([
          _cache.invalidate(_cacheKeyReminderList),
          _cache.invalidate(_cacheKeyDashboard),
        ]);
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

  // -------------------------------------------------------------------------
  // deleteReminder — invalida cache após sucesso
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, Unit>> deleteReminder(String id) async {
    try {
      final response = await _httpClient.delete(AppPath.reminderById(id));

      if (response.isSuccess) {
        await Future.wait([
          _cache.invalidate(_cacheKeyReminderList),
          _cache.invalidate(_cacheKeyDashboard),
        ]);
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
