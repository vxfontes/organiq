import 'package:flutter_modular/flutter_modular.dart';
import 'package:inbota/modules/routines/data/repositories/routine_repository.dart';
import 'package:inbota/modules/routines/domain/repositories/i_routine_repository.dart';
import 'package:inbota/modules/routines/domain/usecases/routine_usecases.dart';

class RoutinesModule {
  static void binds(Injector i) {
    i.addLazySingleton<IRoutineRepository>(RoutineRepository.new);

    i.addLazySingleton(GetRoutinesUsecase.new);
    i.addLazySingleton(GetRoutinesByWeekdayUsecase.new);
    i.addLazySingleton(GetRoutineUsecase.new);
    i.addLazySingleton(CreateRoutineUsecase.new);
    i.addLazySingleton(UpdateRoutineUsecase.new);
    i.addLazySingleton(DeleteRoutineUsecase.new);
    i.addLazySingleton(CompleteRoutineUsecase.new);
    i.addLazySingleton(UncompleteRoutineUsecase.new);
    i.addLazySingleton(GetRoutineHistoryUsecase.new);
    i.addLazySingleton(GetRoutineStreakUsecase.new);
    i.addLazySingleton(GetTodaySummaryUsecase.new);
    i.addLazySingleton(CreateRoutineExceptionUsecase.new);
    i.addLazySingleton(DeleteRoutineExceptionUsecase.new);
  }
}
