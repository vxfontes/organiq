import 'package:dartz/dartz.dart';

import 'package:organiq/modules/tasks/data/models/task_list_output.dart';
import 'package:organiq/modules/tasks/data/models/task_output.dart';
import 'package:organiq/modules/tasks/data/models/task_create_input.dart';
import 'package:organiq/modules/tasks/data/models/task_update_input.dart';
import 'package:organiq/shared/errors/failures.dart';

abstract class ITaskRepository {
  Future<Either<Failure, TaskListOutput>> fetchTasks({
    int? limit,
    String? cursor,
  });
  Future<Either<Failure, TaskOutput>> createTask(TaskCreateInput input);
  Future<Either<Failure, TaskOutput>> updateTask(TaskUpdateInput input);
  Future<Either<Failure, Unit>> deleteTask(String id);
}
