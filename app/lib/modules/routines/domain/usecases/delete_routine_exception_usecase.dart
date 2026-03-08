import 'package:dartz/dartz.dart';
import 'package:inbota/modules/routines/domain/repositories/i_routine_repository.dart';
import 'package:inbota/shared/errors/failures.dart';

class DeleteRoutineExceptionUsecase {
  DeleteRoutineExceptionUsecase(this._repository);

  final IRoutineRepository _repository;

  Future<Either<Failure, Unit>> call(String id, String date) {
    return _repository.deleteException(id, date);
  }
}
