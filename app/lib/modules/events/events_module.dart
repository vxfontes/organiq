import 'package:flutter_modular/flutter_modular.dart';
import 'package:organiq/modules/events/data/repositories/event_repository.dart';
import 'package:organiq/modules/events/domain/repositories/i_event_repository.dart';
import 'package:organiq/modules/events/domain/usecases/create_event_usecase.dart';
import 'package:organiq/modules/events/domain/usecases/delete_event_usecase.dart';
import 'package:organiq/modules/events/domain/usecases/get_agenda_usecase.dart';
import 'package:organiq/modules/events/domain/usecases/get_events_usecase.dart';
import 'package:organiq/shared/services/cache/cache_service.dart';
import 'package:organiq/shared/services/connectivity/connectivity_service.dart';
import 'package:organiq/shared/services/http/http_client.dart';

class EventsModule {
  static void binds(Injector i) {
    i.addLazySingleton<IEventRepository>(
      () => EventRepository(
        i.get<IHttpClient>(),
        i.get<ICacheService>(),
        i.get<IConnectivityService>(),
      ),
    );
    i.addLazySingleton<CreateEventUsecase>(CreateEventUsecase.new);
    i.addLazySingleton<DeleteEventUsecase>(DeleteEventUsecase.new);
    i.addLazySingleton<GetEventsUsecase>(GetEventsUsecase.new);
    i.addLazySingleton<GetAgendaUsecase>(GetAgendaUsecase.new);
  }
}
