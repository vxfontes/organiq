import 'package:dartz/dartz.dart';
import 'package:organiq/modules/routines/data/models/routine_completion_output.dart';
import 'package:organiq/modules/routines/domain/repositories/i_routine_repository.dart';
import 'package:organiq/shared/errors/failures.dart';

class CompleteRoutineUsecase {
  CompleteRoutineUsecase(this._repository);

  final IRoutineRepository _repository;

  Future<Either<Failure, RoutineCompletionOutput>> call(
    String id, {
    String? date,
  }) {
    return _repository.completeRoutine(id, date: date);
  }
}
