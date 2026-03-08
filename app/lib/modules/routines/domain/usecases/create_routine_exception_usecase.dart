import 'package:dartz/dartz.dart';
import 'package:inbota/modules/routines/data/models/routine_exception_input.dart';
import 'package:inbota/modules/routines/data/models/routine_exception_output.dart';
import 'package:inbota/modules/routines/domain/repositories/i_routine_repository.dart';
import 'package:inbota/shared/errors/failures.dart';

class CreateRoutineExceptionUsecase {
  CreateRoutineExceptionUsecase(this._repository);

  final IRoutineRepository _repository;

  Future<Either<Failure, RoutineExceptionOutput>> call(
    String id,
    RoutineExceptionInput input,
  ) {
    return _repository.createException(id, input);
  }
}
