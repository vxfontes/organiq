import 'package:flutter_modular/flutter_modular.dart';
import 'package:organiq/modules/tasks/data/repositories/task_repository.dart';
import 'package:organiq/modules/tasks/domain/repositories/i_task_repository.dart';
import 'package:organiq/modules/tasks/domain/usecases/create_task_usecase.dart';
import 'package:organiq/modules/tasks/domain/usecases/delete_task_usecase.dart';
import 'package:organiq/modules/tasks/domain/usecases/get_tasks_usecase.dart';
import 'package:organiq/modules/tasks/domain/usecases/update_task_usecase.dart';
import 'package:organiq/shared/services/cache/cache_service.dart';
import 'package:organiq/shared/services/connectivity/connectivity_service.dart';
import 'package:organiq/shared/services/http/http_client.dart';

class TasksModule {
  static void binds(Injector i) {
    // repository — recebe IHttpClient (SharedModule), ICacheService e
    // IConnectivityService (ambos também registrados em SharedModule).
    i.addLazySingleton<ITaskRepository>(
      () => TaskRepository(
        i.get<IHttpClient>(),
        i.get<ICacheService>(),
        i.get<IConnectivityService>(),
      ),
    );

    // usecases
    i.addLazySingleton<CreateTaskUsecase>(CreateTaskUsecase.new);
    i.addLazySingleton<DeleteTaskUsecase>(DeleteTaskUsecase.new);
    i.addLazySingleton<GetTasksUsecase>(GetTasksUsecase.new);
    i.addLazySingleton<UpdateTaskUsecase>(UpdateTaskUsecase.new);
  }
}
