import 'package:organiq/modules/events/data/models/agenda_output.dart';
import 'package:organiq/modules/events/domain/repositories/i_event_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/oq_usecase.dart';

class GetAgendaUsecase extends OQUsecase {
  GetAgendaUsecase(this._repository);

  final IEventRepository _repository;

  UsecaseResponse<Failure, AgendaOutput> call({int? limit}) {
    return _repository.fetchAgenda(limit: limit);
  }
}
