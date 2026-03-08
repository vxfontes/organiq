import 'package:dartz/dartz.dart';
import 'package:inbota/modules/routines/data/models/routine_output.dart';
import 'package:inbota/modules/routines/data/models/routine_update_input.dart';
import 'package:inbota/modules/routines/domain/repositories/i_routine_repository.dart';
import 'package:inbota/shared/errors/failures.dart';

class UpdateRoutineUsecase {
  UpdateRoutineUsecase(this._repository);

  final IRoutineRepository _repository;

  Future<Either<Failure, RoutineOutput>> call(
    String id,
    RoutineUpdateInput input,
  ) {
    return _repository.updateRoutine(id, input);
  }
}
