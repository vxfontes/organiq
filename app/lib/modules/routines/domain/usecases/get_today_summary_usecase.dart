import 'package:dartz/dartz.dart';
import 'package:organiq/modules/routines/data/models/routine_today_summary_output.dart';
import 'package:organiq/modules/routines/domain/repositories/i_routine_repository.dart';
import 'package:organiq/shared/errors/failures.dart';

class GetTodaySummaryUsecase {
  GetTodaySummaryUsecase(this._repository);

  final IRoutineRepository _repository;

  Future<Either<Failure, RoutineTodaySummaryOutput>> call() {
    return _repository.getTodaySummary();
  }
}
