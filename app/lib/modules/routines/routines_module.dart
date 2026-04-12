import 'package:flutter_modular/flutter_modular.dart';
import 'package:organiq/modules/routines/data/repositories/routine_repository.dart';
import 'package:organiq/modules/routines/domain/repositories/i_routine_repository.dart';
import 'package:organiq/modules/routines/domain/usecases/complete_routine_usecase.dart';
import 'package:organiq/modules/routines/domain/usecases/create_routine_exception_usecase.dart';
import 'package:organiq/modules/routines/domain/usecases/create_routine_usecase.dart';
import 'package:organiq/modules/routines/domain/usecases/delete_routine_exception_usecase.dart';
import 'package:organiq/modules/routines/domain/usecases/delete_routine_usecase.dart';
import 'package:organiq/modules/routines/domain/usecases/get_routine_history_usecase.dart';
import 'package:organiq/modules/routines/domain/usecases/get_routine_streak_usecase.dart';
import 'package:organiq/modules/routines/domain/usecases/get_routine_usecase.dart';
import 'package:organiq/modules/routines/domain/usecases/get_routines_by_weekday_usecase.dart';
import 'package:organiq/modules/routines/domain/usecases/get_routines_usecase.dart';
import 'package:organiq/modules/routines/domain/usecases/get_today_summary_usecase.dart';
import 'package:organiq/modules/routines/domain/usecases/toggle_routine_usecase.dart';
import 'package:organiq/modules/routines/domain/usecases/uncomplete_routine_usecase.dart';
import 'package:organiq/modules/routines/domain/usecases/update_routine_usecase.dart';
import 'package:organiq/shared/services/cache/cache_service.dart';
import 'package:organiq/shared/services/connectivity/connectivity_service.dart';
import 'package:organiq/shared/services/http/http_client.dart';

class RoutinesModule {
  static void binds(Injector i) {
    i.addLazySingleton<IRoutineRepository>(
      () => RoutineRepository(
        i.get<IHttpClient>(),
        i.get<ICacheService>(),
        i.get<IConnectivityService>(),
      ),
    );

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
    i.addLazySingleton(ToggleRoutineUsecase.new);
    i.addLazySingleton(GetTodaySummaryUsecase.new);
    i.addLazySingleton(CreateRoutineExceptionUsecase.new);
    i.addLazySingleton(DeleteRoutineExceptionUsecase.new);
  }
}
