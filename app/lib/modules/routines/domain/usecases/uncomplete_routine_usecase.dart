import 'package:dartz/dartz.dart';
import 'package:organiq/modules/routines/domain/repositories/i_routine_repository.dart';
import 'package:organiq/shared/errors/failures.dart';

class UncompleteRoutineUsecase {
  UncompleteRoutineUsecase(this._repository);

  final IRoutineRepository _repository;

  Future<Either<Failure, Unit>> call(String id, String date) {
    return _repository.uncompleteRoutine(id, date);
  }
}
