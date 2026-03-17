import 'package:organiq/modules/events/data/models/event_create_input.dart';
import 'package:organiq/modules/events/data/models/event_output.dart';
import 'package:organiq/modules/events/domain/repositories/i_event_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/ib_usecase.dart';

class CreateEventUsecase extends IBUsecase {
  CreateEventUsecase(this._repository);

  final IEventRepository _repository;

  UsecaseResponse<Failure, EventOutput> call(EventCreateInput input) {
    return _repository.createEvent(input);
  }
}
