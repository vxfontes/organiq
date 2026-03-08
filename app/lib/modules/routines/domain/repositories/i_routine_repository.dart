import 'package:dartz/dartz.dart';
import 'package:inbota/modules/routines/data/models/routine_exception_input.dart';
import 'package:inbota/modules/routines/data/models/routine_exception_output.dart';
import 'package:inbota/modules/routines/data/models/routine_list_output.dart';
import 'package:inbota/modules/routines/data/models/routine_streak_output.dart';
import 'package:inbota/modules/routines/data/models/routine_today_summary_output.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/modules/routines/data/models/routine_completion_output.dart';
import 'package:inbota/modules/routines/data/models/routine_create_input.dart';
import 'package:inbota/modules/routines/data/models/routine_output.dart';
import 'package:inbota/modules/routines/data/models/routine_update_input.dart';

abstract class IRoutineRepository {
  Future<Either<Failure, RoutineListOutput>> fetchRoutines({
    int? limit,
    String? cursor,
  });

  Future<Either<Failure, RoutineListOutput>> fetchRoutinesByWeekday(int weekday, {String? date});

  Future<Either<Failure, RoutineOutput>> getRoutine(String id);

  Future<Either<Failure, RoutineOutput>> createRoutine(RoutineCreateInput input);

  Future<Either<Failure, RoutineOutput>> updateRoutine(
    String id,
    RoutineUpdateInput input,
  );

  Future<Either<Failure, Unit>> deleteRoutine(String id);

  Future<Either<Failure, Unit>> toggleRoutine(String id, bool isActive);

  Future<Either<Failure, RoutineCompletionOutput>> completeRoutine(
    String id, {
    String? date,
  });

  Future<Either<Failure, Unit>> uncompleteRoutine(String id, String date);

  Future<Either<Failure, List<RoutineCompletionOutput>>> getRoutineHistory(
    String id,
  );

  Future<Either<Failure, RoutineStreakOutput>> getRoutineStreak(String id);

  Future<Either<Failure, RoutineTodaySummaryOutput>> getTodaySummary();

  Future<Either<Failure, RoutineExceptionOutput>> createException(
    String id,
    RoutineExceptionInput input,
  );

  Future<Either<Failure, Unit>> deleteException(String id, String date);
}
