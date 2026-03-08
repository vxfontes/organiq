import 'package:dartz/dartz.dart';
import 'package:inbota/modules/routines/data/models/routine_streak_output.dart';
import 'package:inbota/modules/routines/domain/repositories/i_routine_repository.dart';
import 'package:inbota/shared/errors/failures.dart';

class GetRoutineStreakUsecase {
  GetRoutineStreakUsecase(this._repository);

  final IRoutineRepository _repository;

  Future<Either<Failure, RoutineStreakOutput>> call(String id) {
    return _repository.getRoutineStreak(id);
  }
}
