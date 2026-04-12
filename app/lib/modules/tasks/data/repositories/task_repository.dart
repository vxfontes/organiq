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
import 'package:organiq/shared/services/http/app_path.dart';
import 'package:organiq/shared/services/http/http_client.dart';

class TaskRepository implements ITaskRepository {
  TaskRepository(this._httpClient);

  final IHttpClient _httpClient;
  @override
  Future<Either<Failure, TaskListOutput>> fetchTasks({
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
        return Right(TaskListOutput.fromJson(response.asMap()));
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

  @override
  Future<Either<Failure, TaskOutput>> createTask(TaskCreateInput input) async {
    try {
      final response = await _httpClient.post(
        AppPath.tasks,
        data: input.toJson(),
      );

      if (response.isSuccess) {
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

  @override
  Future<Either<Failure, TaskOutput>> updateTask(TaskUpdateInput input) async {
    try {
      final response = await _httpClient.patch(
        AppPath.taskById(input.id),
        data: input.toJson(),
      );

      if (response.isSuccess) {
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

  @override
  Future<Either<Failure, Unit>> deleteTask(String id) async {
    try {
      final response = await _httpClient.delete(AppPath.taskById(id));

      if (response.isSuccess) {
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
