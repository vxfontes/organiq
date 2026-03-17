import 'package:dartz/dartz.dart' show Unit;
import 'package:organiq/modules/events/domain/repositories/i_event_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/oq_usecase.dart';

class DeleteEventUsecase extends OQUsecase {
  DeleteEventUsecase(this._repository);

  final IEventRepository _repository;

  UsecaseResponse<Failure, Unit> call(String id) {
    return _repository.deleteEvent(id);
  }
}
