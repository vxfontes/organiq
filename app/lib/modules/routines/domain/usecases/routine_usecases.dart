import 'package:dartz/dartz.dart';
import 'package:inbota/modules/routines/data/models/routine_completion_output.dart';
import 'package:inbota/modules/routines/data/models/routine_create_input.dart';
import 'package:inbota/modules/routines/data/models/routine_output.dart';
import 'package:inbota/modules/routines/data/models/routine_update_input.dart';
import 'package:inbota/modules/routines/domain/repositories/i_routine_repository.dart';
import 'package:inbota/shared/errors/failures.dart';

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

class GetRoutinesByWeekdayUsecase {
  GetRoutinesByWeekdayUsecase(this._repository);

  final IRoutineRepository _repository;

  Future<Either<Failure, RoutineListOutput>> call(int weekday) {
    return _repository.fetchRoutinesByWeekday(weekday);
  }
}

class GetRoutineUsecase {
  GetRoutineUsecase(this._repository);

  final IRoutineRepository _repository;

  Future<Either<Failure, RoutineOutput>> call(String id) {
    return _repository.getRoutine(id);
  }
}

class CreateRoutineUsecase {
  CreateRoutineUsecase(this._repository);

  final IRoutineRepository _repository;

  Future<Either<Failure, RoutineOutput>> call(RoutineCreateInput input) {
    return _repository.createRoutine(input);
  }
}

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

class DeleteRoutineUsecase {
  DeleteRoutineUsecase(this._repository);

  final IRoutineRepository _repository;

  Future<Either<Failure, Unit>> call(String id) {
    return _repository.deleteRoutine(id);
  }
}

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

class UncompleteRoutineUsecase {
  UncompleteRoutineUsecase(this._repository);

  final IRoutineRepository _repository;

  Future<Either<Failure, Unit>> call(String id, String date) {
    return _repository.uncompleteRoutine(id, date);
  }
}

class GetRoutineHistoryUsecase {
  GetRoutineHistoryUsecase(this._repository);

  final IRoutineRepository _repository;

  Future<Either<Failure, List<RoutineCompletionOutput>>> call(String id) {
    return _repository.getRoutineHistory(id);
  }
}

class GetRoutineStreakUsecase {
  GetRoutineStreakUsecase(this._repository);

  final IRoutineRepository _repository;

  Future<Either<Failure, RoutineStreakOutput>> call(String id) {
    return _repository.getRoutineStreak(id);
  }
}

class GetTodaySummaryUsecase {
  GetTodaySummaryUsecase(this._repository);

  final IRoutineRepository _repository;

  Future<Either<Failure, RoutineTodaySummaryOutput>> call() {
    return _repository.getTodaySummary();
  }
}

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

class DeleteRoutineExceptionUsecase {
  DeleteRoutineExceptionUsecase(this._repository);

  final IRoutineRepository _repository;

  Future<Either<Failure, Unit>> call(String id, String date) {
    return _repository.deleteException(id, date);
  }
}
