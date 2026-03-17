import 'package:organiq/modules/tasks/data/models/task_create_input.dart';
import 'package:organiq/modules/tasks/data/models/task_output.dart';
import 'package:organiq/modules/tasks/domain/repositories/i_task_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/ib_usecase.dart';

class CreateTaskUsecase extends IBUsecase {
  final ITaskRepository _repository;

  CreateTaskUsecase(this._repository);

  UsecaseResponse<Failure, TaskOutput> call(TaskCreateInput input) {
    return _repository.createTask(input);
  }
}
