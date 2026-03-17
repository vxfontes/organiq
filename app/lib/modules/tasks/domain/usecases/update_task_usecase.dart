import 'package:organiq/modules/tasks/data/models/task_output.dart';
import 'package:organiq/modules/tasks/data/models/task_update_input.dart';
import 'package:organiq/modules/tasks/domain/repositories/i_task_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/oq_usecase.dart';

class UpdateTaskUsecase extends OQUsecase {
  final ITaskRepository _repository;

  UpdateTaskUsecase(this._repository);

  UsecaseResponse<Failure, TaskOutput> call(TaskUpdateInput input) {
    return _repository.updateTask(input);
  }
}
