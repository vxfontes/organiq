import 'package:dartz/dartz.dart';
import 'package:inbota/modules/routines/data/models/routine_list_output.dart';
import 'package:inbota/modules/routines/domain/repositories/i_routine_repository.dart';
import 'package:inbota/shared/errors/failures.dart';

class GetRoutinesByWeekdayUsecase {
  GetRoutinesByWeekdayUsecase(this._repository);

  final IRoutineRepository _repository;

  Future<Either<Failure, RoutineListOutput>> call(int weekday, {String? date}) {
    return _repository.fetchRoutinesByWeekday(weekday, date: date);
  }
}
