import 'package:organiq/modules/tasks/data/models/task_list_output.dart';
import 'package:organiq/modules/tasks/domain/repositories/i_task_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/ib_usecase.dart';

class GetTasksUsecase extends IBUsecase {
  final ITaskRepository _repository;

  GetTasksUsecase(this._repository);

  UsecaseResponse<Failure, TaskListOutput> call({int? limit, String? cursor}) {
    return _repository.fetchTasks(limit: limit, cursor: cursor);
  }
}
