import 'package:dartz/dartz.dart' show Unit;
import 'package:organiq/modules/tasks/domain/repositories/i_task_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/oq_usecase.dart';

class DeleteTaskUsecase extends OQUsecase {
  DeleteTaskUsecase(this._repository);

  final ITaskRepository _repository;

  UsecaseResponse<Failure, Unit> call(String id) {
    return _repository.deleteTask(id);
  }
}
