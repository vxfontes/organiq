import 'package:dartz/dartz.dart';
import 'package:organiq/modules/routines/data/models/routine_list_output.dart';
import 'package:organiq/modules/routines/domain/repositories/i_routine_repository.dart';
import 'package:organiq/shared/errors/failures.dart';

class GetRoutinesUsecase {
  GetRoutinesUsecase(this._repository);

  final IRoutineRepository _repository;

  Future<Either<Failure, RoutineListOutput>> call({
    int? limit,
    String? cursor,
  }) {
    return _repository.fetchRoutines(limit: limit, cursor: cursor);
  }
}
