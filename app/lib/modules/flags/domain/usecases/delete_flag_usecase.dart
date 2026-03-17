import 'package:dartz/dartz.dart' show Unit;
import 'package:organiq/modules/flags/domain/repositories/i_flag_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/oq_usecase.dart';

class DeleteFlagUsecase extends OQUsecase {
  DeleteFlagUsecase(this._repository);

  final IFlagRepository _repository;

  UsecaseResponse<Failure, Unit> call(String id) {
    return _repository.deleteFlag(id);
  }
}
