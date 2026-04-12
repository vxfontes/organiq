import 'package:dartz/dartz.dart';

import 'package:organiq/modules/tasks/data/models/task_list_output.dart';
import 'package:organiq/modules/tasks/data/models/task_output.dart';
import 'package:organiq/modules/tasks/data/models/task_create_input.dart';
import 'package:organiq/modules/tasks/data/models/task_update_input.dart';
import 'package:organiq/modules/tasks/domain/repositories/i_task_repository.dart';
import 'package:organiq/shared/errors/api_error_mapper.dart';
import 'package:organiq/shared/errors/exception_mapper.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/extensions/response_model_extensions.dart';
import 'package:organiq/shared/services/cache/cache_service.dart';
import 'package:organiq/shared/services/connectivity/connectivity_service.dart';
import 'package:organiq/shared/services/http/app_path.dart';
import 'package:organiq/shared/services/http/http_client.dart';

// Chave de cache para a lista de tasks. Parâmetros de paginação (limit/cursor)
// são ignorados intencionalmente: cacheamos a primeira página (sem cursor),
// que é o caso de uso dominante. Páginas com cursor são buscadas sempre da API.
const _cacheKeyTaskList = 'cache:${AppPath.tasks}';
const _cacheKeyDashboard = 'cache:${AppPath.homeDashboard}';

class TaskRepository implements ITaskRepository {
  TaskRepository(this._httpClient, this._cache, this._connectivity);

  final IHttpClient _httpClient;
  final ICacheService _cache;
  final IConnectivityService _connectivity;

  // -------------------------------------------------------------------------
  // fetchTasks — estratégia cache-first
  //
  // 1. Tem cursor (paginação): vai direto à API — não cacheamos páginas
  //    intermediárias para evitar inconsistência com mutações.
  // 2. Sem cursor e cache válido: retorna cache independente de conectividade.
  // 3. Sem cursor, cache ausente/expirado, offline: retorna NetworkFailure.
  // 4. Sem cursor, cache ausente/expirado, online: busca API, atualiza cache.
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, TaskListOutput>> fetchTasks({
    int? limit,
    String? cursor,
  }) async {
    // Paginação: nunca usa cache para cursores intermediários.
    if (cursor != null) {
      return _fetchTasksFromApi(limit: limit, cursor: cursor);
    }

    // Tenta servir do cache (válido = TTL não expirado).
    final cached = await _cache.get(_cacheKeyTaskList);
    if (cached != null) {
      try {
        return Right(TaskListOutput.fromJson(cached));
      } catch (_) {
        // Cache corrompido — invalida e cai no fluxo normal.
        await _cache.invalidate(_cacheKeyTaskList);
      }
    }

    // Cache ausente ou expirado: verifica conectividade.
    final online = await _connectivity.isOnline();
    if (!online) {
      return Left(
        NetworkFailure(
          message:
              'Sem conexão. Conecte-se à internet para carregar suas tarefas.',
        ),
      );
    }

    return _fetchTasksFromApi(limit: limit);
  }

  Future<Either<Failure, TaskListOutput>> _fetchTasksFromApi({
    int? limit,
    String? cursor,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (limit != null) query['limit'] = limit;
      if (cursor != null) query['cursor'] = cursor;

      final response = await _httpClient.get(
        AppPath.tasks,
        queryParameters: query.isEmpty ? null : query,
      );

      if (response.isSuccess) {
        final output = TaskListOutput.fromJson(response.asMap());
        // Atualiza cache apenas para a primeira página (sem cursor).
        if (cursor == null) {
          await _cache.set(_cacheKeyTaskList, response.asMap());
        }
        return Right(output);
      }

      return Left(
        GetListFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao carregar tarefas.',
          ),
        ),
      );
    } catch (err) {
      return Left(
        ExceptionMapper.toFailure(
          err,
          fallbackMessage: 'Erro ao carregar tarefas.',
          failureFactory: (msg) => GetListFailure(message: msg),
        ),
      );
    }
  }

  // -------------------------------------------------------------------------
  // createTask — invalida cache após sucesso
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, TaskOutput>> createTask(TaskCreateInput input) async {
    try {
      final response = await _httpClient.post(
        AppPath.tasks,
        data: input.toJson(),
      );

      if (response.isSuccess) {
        await Future.wait([
          _cache.invalidate(_cacheKeyTaskList),
          _cache.invalidate(_cacheKeyDashboard),
        ]);
        return Right(TaskOutput.fromJson(response.asMap()));
      }

      return Left(
        SaveFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao criar tarefa.',
          ),
        ),
      );
    } catch (err) {
      return Left(
        ExceptionMapper.toFailure(
          err,
          fallbackMessage: 'Erro ao criar tarefa.',
          failureFactory: (msg) => SaveFailure(message: msg),
        ),
      );
    }
  }

  // -------------------------------------------------------------------------
  // updateTask — invalida cache após sucesso
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, TaskOutput>> updateTask(TaskUpdateInput input) async {
    try {
      final response = await _httpClient.patch(
        AppPath.taskById(input.id),
        data: input.toJson(),
      );

      if (response.isSuccess) {
        await Future.wait([
          _cache.invalidate(_cacheKeyTaskList),
          _cache.invalidate(_cacheKeyDashboard),
        ]);
        return Right(TaskOutput.fromJson(response.asMap()));
      }

      return Left(
        UpdateFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao atualizar tarefa.',
          ),
        ),
      );
    } catch (err) {
      return Left(
        ExceptionMapper.toFailure(
          err,
          fallbackMessage: 'Erro ao atualizar tarefa.',
          failureFactory: (msg) => UpdateFailure(message: msg),
        ),
      );
    }
  }

  // -------------------------------------------------------------------------
  // deleteTask — invalida cache após sucesso
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, Unit>> deleteTask(String id) async {
    try {
      final response = await _httpClient.delete(AppPath.taskById(id));

      if (response.isSuccess) {
        await Future.wait([
          _cache.invalidate(_cacheKeyTaskList),
          _cache.invalidate(_cacheKeyDashboard),
        ]);
        return const Right(unit);
      }

      return Left(
        DeleteFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao excluir tarefa.',
          ),
        ),
      );
    } catch (err) {
      return Left(
        ExceptionMapper.toFailure(
          err,
          fallbackMessage: 'Erro ao excluir tarefa.',
          failureFactory: (msg) => DeleteFailure(message: msg),
        ),
      );
    }
  }
}
