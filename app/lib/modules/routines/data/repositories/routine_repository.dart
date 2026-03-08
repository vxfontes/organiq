import 'package:dartz/dartz.dart';

import 'package:inbota/modules/routines/data/models/routine_completion_output.dart';
import 'package:inbota/modules/routines/data/models/routine_create_input.dart';
import 'package:inbota/modules/routines/data/models/routine_exception_input.dart';
import 'package:inbota/modules/routines/data/models/routine_exception_output.dart';
import 'package:inbota/modules/routines/data/models/routine_list_output.dart';
import 'package:inbota/modules/routines/data/models/routine_output.dart';
import 'package:inbota/modules/routines/data/models/routine_streak_output.dart';
import 'package:inbota/modules/routines/data/models/routine_today_summary_output.dart';
import 'package:inbota/modules/routines/data/models/routine_update_input.dart';
import 'package:inbota/modules/routines/domain/repositories/i_routine_repository.dart';
import 'package:inbota/shared/errors/api_error_mapper.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/services/http/app_path.dart';
import 'package:inbota/shared/services/http/http_client.dart';

class RoutineRepository implements IRoutineRepository {
  RoutineRepository(this._httpClient);

  final IHttpClient _httpClient;

  @override
  Future<Either<Failure, RoutineListOutput>> fetchRoutines({
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
  Future<Either<Failure, RoutineListOutput>> fetchRoutinesByWeekday(
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

  @override
  Future<Either<Failure, Unit>> deleteRoutine(String id) async {
    try {
      final response = await _httpClient.delete(AppPath.routineById(id));

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
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

  @override
  Future<Either<Failure, Unit>> toggleRoutine(String id, bool isActive) async {
    try {
      final response = await _httpClient.patch(
        AppPath.routineToggle(id),
        data: {'isActive': isActive},
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
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
        return Right(
          RoutineCompletionOutput.fromJson(_asMap(response.data)),
        );
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

  @override
  Future<Either<Failure, Unit>> uncompleteRoutine(String id, String date) async {
    try {
      final response = await _httpClient.delete(
        AppPath.routineCompleteByDate(id, date),
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
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

  @override
  Future<Either<Failure, RoutineTodaySummaryOutput>> getTodaySummary() async {
    try {
      final response = await _httpClient.get(AppPath.routineTodaySummary);

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        return Right(
          RoutineTodaySummaryOutput.fromJson(_asMap(response.data)),
        );
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
        return Right(
          RoutineExceptionOutput.fromJson(_asMap(response.data)),
        );
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

  @override
  Future<Either<Failure, Unit>> deleteException(String id, String date) async {
    try {
      final response = await _httpClient.delete(
        AppPath.routineExceptionByDate(id, date),
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
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
}
