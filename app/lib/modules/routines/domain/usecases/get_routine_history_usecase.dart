import 'package:dartz/dartz.dart';
import 'package:organiq/modules/routines/data/models/routine_completion_output.dart';
import 'package:organiq/modules/routines/domain/repositories/i_routine_repository.dart';
import 'package:organiq/shared/errors/failures.dart';

class GetRoutineHistoryUsecase {
  GetRoutineHistoryUsecase(this._repository);

  final IRoutineRepository _repository;

  Future<Either<Failure, List<RoutineCompletionOutput>>> call(String id) {
    return _repository.getRoutineHistory(id);
  }
}
