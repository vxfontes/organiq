import 'package:organiq/modules/events/data/models/event_list_output.dart';
import 'package:organiq/modules/events/domain/repositories/i_event_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/ib_usecase.dart';

class GetEventsUsecase extends IBUsecase {
  GetEventsUsecase(this._repository);

  final IEventRepository _repository;

  UsecaseResponse<Failure, EventListOutput> call({int? limit, String? cursor}) {
    return _repository.fetchEvents(limit: limit, cursor: cursor);
  }
}
