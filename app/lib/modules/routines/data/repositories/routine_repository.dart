import 'package:dartz/dartz.dart';

import 'package:organiq/modules/routines/data/models/routine_completion_output.dart';
import 'package:organiq/modules/routines/data/models/routine_create_input.dart';
import 'package:organiq/modules/routines/data/models/routine_exception_input.dart';
import 'package:organiq/modules/routines/data/models/routine_exception_output.dart';
import 'package:organiq/modules/routines/data/models/routine_list_output.dart';
import 'package:organiq/modules/routines/data/models/routine_output.dart';
import 'package:organiq/modules/routines/data/models/routine_streak_output.dart';
import 'package:organiq/modules/routines/data/models/routine_today_summary_output.dart';
import 'package:organiq/modules/routines/data/models/routine_update_input.dart';
import 'package:organiq/modules/routines/domain/repositories/i_routine_repository.dart';
import 'package:organiq/shared/errors/api_error_mapper.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/services/cache/cache_service.dart';
import 'package:organiq/shared/services/connectivity/connectivity_service.dart';
import 'package:organiq/shared/services/http/app_path.dart';
import 'package:organiq/shared/services/http/http_client.dart';

const _cacheKeyRoutines = 'cache:${AppPath.routines}';
const _cacheKeyTodaySummary = 'cache:${AppPath.routineTodaySummary}';
const _cacheKeyDashboard = 'cache:${AppPath.homeDashboard}';
const _todaySummaryTtl = Duration(minutes: 2);

String _cacheKeyRoutineDay(int weekday) =>
    'cache:${AppPath.routineDay(weekday)}';

class RoutineRepository implements IRoutineRepository {
  RoutineRepository(this._httpClient, this._cache, this._connectivity);

  final IHttpClient _httpClient;
  final ICacheService _cache;
  final IConnectivityService _connectivity;

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic data) {
    if (data is List) return data;
    return [];
  }

  // -------------------------------------------------------------------------
  // _invalidateMutationCaches — invalida caches afetados por mutações
  //
  // Mutações alteram a lista geral de rotinas e o resumo de hoje; ambos
  // precisam ser invalidados. Cache por weekday tem TTL de 5min e é tolerado
  // ficar stale até expiração natural para evitar invalidação massiva.
  // -------------------------------------------------------------------------
  Future<void> _invalidateMutationCaches() async {
    await Future.wait([
      _cache.invalidate(_cacheKeyRoutines),
      _cache.invalidate(_cacheKeyTodaySummary),
      _cache.invalidate(_cacheKeyDashboard),
    ]);
  }

  // -------------------------------------------------------------------------
  // fetchRoutines — estratégia cache-first com TTL de 5min
  //
  // 1. Tem cursor (paginação): vai direto à API.
  // 2. Sem cursor e cache válido: retorna cache.
  // 3. Sem cursor, cache ausente/expirado, offline: retorna NetworkFailure.
  // 4. Sem cursor, cache ausente/expirado, online: busca API, atualiza cache.
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, RoutineListOutput>> fetchRoutines({
    int? limit,
    String? cursor,
  }) async {
    if (cursor != null) {
      return _fetchRoutinesFromApi(limit: limit, cursor: cursor);
    }

    final cached = await _cache.get(_cacheKeyRoutines);
    if (cached != null) {
      try {
        return Right(RoutineListOutput.fromJson(cached));
      } catch (_) {
        await _cache.invalidate(_cacheKeyRoutines);
      }
    }

    final online = await _connectivity.isOnline();
    if (!online) {
      return Left(
        NetworkFailure(
          message:
              'Sem conexão. Conecte-se à internet para carregar suas rotinas.',
        ),
      );
    }

    return _fetchRoutinesFromApi(limit: limit);
  }

  Future<Either<Failure, RoutineListOutput>> _fetchRoutinesFromApi({
    int? limit,
    String? cursor,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (limit != null) query['limit'] = limit;
      if (cursor != null) query['cursor'] = cursor;

      final response = await _httpClient.get(
        AppPath.routines,
        queryParameters: query.isEmpty ? null : query,
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        final data = _asMap(response.data);
        if (cursor == null) {
          await _cache.set(_cacheKeyRoutines, data);
        }
        return Right(RoutineListOutput.fromJson(data));
      }

      return Left(
        GetListFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao carregar rotinas.',
          ),
        ),
      );
    } catch (err) {
      return Left(GetListFailure(message: err.toString()));
    }
  }

  // -------------------------------------------------------------------------
  // fetchRoutinesByWeekday — estratégia cache-first com TTL de 5min
  //
  // Chave inclui o weekday para evitar colisões entre dias distintos.
  // fetchRoutinesByWeekday não tem paginação por cursor — sempre cacheia.
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, RoutineListOutput>> fetchRoutinesByWeekday(
    int weekday, {
    String? date,
  }) async {
    final cacheKey = _cacheKeyRoutineDay(weekday);

    // Com parâmetro date (consulta histórica específica): vai direto à API.
    if (date != null) {
      return _fetchRoutinesByWeekdayFromApi(weekday, date: date);
    }

    final cached = await _cache.get(cacheKey);
    if (cached != null) {
      try {
        return Right(RoutineListOutput.fromJson(cached));
      } catch (_) {
        await _cache.invalidate(cacheKey);
      }
    }

    final online = await _connectivity.isOnline();
    if (!online) {
      return Left(
        NetworkFailure(
          message:
              'Sem conexão. Conecte-se à internet para carregar as rotinas do dia.',
        ),
      );
    }

    return _fetchRoutinesByWeekdayFromApi(weekday);
  }

  Future<Either<Failure, RoutineListOutput>> _fetchRoutinesByWeekdayFromApi(
    int weekday, {
    String? date,
  }) async {
    try {
      final response = await _httpClient.get(
        AppPath.routineDay(weekday),
        queryParameters: date != null ? {'date': date} : null,
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        final data = _asMap(response.data);
        if (date == null) {
          await _cache.set(_cacheKeyRoutineDay(weekday), data);
        }
        return Right(RoutineListOutput.fromJson(data));
      }

      return Left(
        GetListFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao carregar rotinas.',
          ),
        ),
      );
    } catch (err) {
      return Left(GetListFailure(message: err.toString()));
    }
  }

  @override
  Future<Either<Failure, RoutineOutput>> getRoutine(String id) async {
    try {
      final response = await _httpClient.get(AppPath.routineById(id));

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        return Right(RoutineOutput.fromJson(_asMap(response.data)));
      }

      return Left(
        GetFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao carregar rotina.',
          ),
        ),
      );
    } catch (err) {
      return Left(GetFailure(message: err.toString()));
    }
  }

  // -------------------------------------------------------------------------
  // createRoutine — invalida caches após sucesso
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, RoutineOutput>> createRoutine(
    RoutineCreateInput input,
  ) async {
    try {
      final response = await _httpClient.post(
        AppPath.routines,
        data: input.toJson(),
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        await _invalidateMutationCaches();
        return Right(RoutineOutput.fromJson(_asMap(response.data)));
      }

      return Left(
        SaveFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao criar rotina.',
          ),
        ),
      );
    } catch (err) {
      return Left(SaveFailure(message: err.toString()));
    }
  }

  // -------------------------------------------------------------------------
  // updateRoutine — invalida caches após sucesso
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, RoutineOutput>> updateRoutine(
    String id,
    RoutineUpdateInput input,
  ) async {
    try {
      final response = await _httpClient.patch(
        AppPath.routineById(id),
        data: input.toJson(),
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        await _invalidateMutationCaches();
        return Right(RoutineOutput.fromJson(_asMap(response.data)));
      }

      return Left(
        UpdateFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao atualizar rotina.',
          ),
        ),
      );
    } catch (err) {
      return Left(UpdateFailure(message: err.toString()));
    }
  }

  // -------------------------------------------------------------------------
  // deleteRoutine — invalida caches após sucesso
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, Unit>> deleteRoutine(String id) async {
    try {
      final response = await _httpClient.delete(AppPath.routineById(id));

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        await _invalidateMutationCaches();
        return const Right(unit);
      }

      return Left(
        DeleteFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao excluir rotina.',
          ),
        ),
      );
    } catch (err) {
      return Left(DeleteFailure(message: err.toString()));
    }
  }

  // -------------------------------------------------------------------------
  // toggleRoutine — invalida caches após sucesso
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, Unit>> toggleRoutine(String id, bool isActive) async {
    try {
      final response = await _httpClient.patch(
        AppPath.routineToggle(id),
        data: {'isActive': isActive},
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        await _invalidateMutationCaches();
        return const Right(unit);
      }

      return Left(
        UpdateFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao alternar rotina.',
          ),
        ),
      );
    } catch (err) {
      return Left(UpdateFailure(message: err.toString()));
    }
  }

  // -------------------------------------------------------------------------
  // completeRoutine — invalida caches após sucesso
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, RoutineCompletionOutput>> completeRoutine(
    String id, {
    String? date,
  }) async {
    try {
      final response = await _httpClient.post(
        AppPath.routineComplete(id),
        data: date != null ? {'date': date} : null,
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        await _invalidateMutationCaches();
        return Right(RoutineCompletionOutput.fromJson(_asMap(response.data)));
      }

      return Left(
        SaveFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao concluir rotina.',
          ),
        ),
      );
    } catch (err) {
      return Left(SaveFailure(message: err.toString()));
    }
  }

  // -------------------------------------------------------------------------
  // uncompleteRoutine — invalida caches após sucesso
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, Unit>> uncompleteRoutine(
    String id,
    String date,
  ) async {
    try {
      final response = await _httpClient.delete(
        AppPath.routineCompleteByDate(id, date),
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        await _invalidateMutationCaches();
        return const Right(unit);
      }

      return Left(
        DeleteFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao remover conclusão.',
          ),
        ),
      );
    } catch (err) {
      return Left(DeleteFailure(message: err.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RoutineCompletionOutput>>> getRoutineHistory(
    String id,
  ) async {
    try {
      final response = await _httpClient.get(AppPath.routineHistory(id));

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        final data = _asList(response.data);
        final items = data
            .map((e) => RoutineCompletionOutput.fromJson(_asMap(e)))
            .toList();
        return Right(items);
      }

      return Left(
        GetListFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao carregar histórico.',
          ),
        ),
      );
    } catch (err) {
      return Left(GetListFailure(message: err.toString()));
    }
  }

  @override
  Future<Either<Failure, RoutineStreakOutput>> getRoutineStreak(
    String id,
  ) async {
    try {
      final response = await _httpClient.get(AppPath.routineStreak(id));

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        return Right(RoutineStreakOutput.fromJson(_asMap(response.data)));
      }

      return Left(
        GetFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao carregar streak.',
          ),
        ),
      );
    } catch (err) {
      return Left(GetFailure(message: err.toString()));
    }
  }

  // -------------------------------------------------------------------------
  // getTodaySummary — estratégia cache-first com TTL de 2min
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, RoutineTodaySummaryOutput>> getTodaySummary() async {
    final cached = await _cache.get(_cacheKeyTodaySummary);
    if (cached != null) {
      try {
        return Right(RoutineTodaySummaryOutput.fromJson(cached));
      } catch (_) {
        await _cache.invalidate(_cacheKeyTodaySummary);
      }
    }

    final online = await _connectivity.isOnline();
    if (!online) {
      return Left(
        NetworkFailure(
          message:
              'Sem conexão. Conecte-se à internet para carregar o resumo de hoje.',
        ),
      );
    }

    return _fetchTodaySummaryFromApi();
  }

  Future<Either<Failure, RoutineTodaySummaryOutput>>
      _fetchTodaySummaryFromApi() async {
    try {
      final response = await _httpClient.get(AppPath.routineTodaySummary);

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        final data = _asMap(response.data);
        await _cache.set(_cacheKeyTodaySummary, data, ttl: _todaySummaryTtl);
        return Right(RoutineTodaySummaryOutput.fromJson(data));
      }

      return Left(
        GetFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao carregar resumo.',
          ),
        ),
      );
    } catch (err) {
      return Left(GetFailure(message: err.toString()));
    }
  }

  // -------------------------------------------------------------------------
  // createException — invalida caches após sucesso
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, RoutineExceptionOutput>> createException(
    String id,
    RoutineExceptionInput input,
  ) async {
    try {
      final response = await _httpClient.post(
        AppPath.routineExceptions(id),
        data: input.toJson(),
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        await _invalidateMutationCaches();
        return Right(RoutineExceptionOutput.fromJson(_asMap(response.data)));
      }

      return Left(
        SaveFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao criar exceção.',
          ),
        ),
      );
    } catch (err) {
      return Left(SaveFailure(message: err.toString()));
    }
  }

  // -------------------------------------------------------------------------
  // deleteException — invalida caches após sucesso
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, Unit>> deleteException(String id, String date) async {
    try {
      final response = await _httpClient.delete(
        AppPath.routineExceptionByDate(id, date),
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        await _invalidateMutationCaches();
        return const Right(unit);
      }

      return Left(
        DeleteFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao excluir exceção.',
          ),
        ),
      );
    } catch (err) {
      return Left(DeleteFailure(message: err.toString()));
    }
  }
}
