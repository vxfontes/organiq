import 'package:dartz/dartz.dart';
import 'package:inbota/modules/routines/data/models/routine_create_input.dart';
import 'package:inbota/modules/routines/data/models/routine_output.dart';
import 'package:inbota/modules/routines/domain/repositories/i_routine_repository.dart';
import 'package:inbota/shared/errors/failures.dart';

class CreateRoutineUsecase {
  CreateRoutineUsecase(this._repository);

  final IRoutineRepository _repository;

  Future<Either<Failure, RoutineOutput>> call(RoutineCreateInput input) {
    return _repository.createRoutine(input);
  }
}
