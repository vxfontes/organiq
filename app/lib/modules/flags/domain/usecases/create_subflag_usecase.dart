import 'package:organiq/modules/flags/data/models/subflag_create_input.dart';
import 'package:organiq/modules/flags/data/models/subflag_output.dart';
import 'package:organiq/modules/flags/domain/repositories/i_flag_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/oq_usecase.dart';

class CreateSubflagUsecase extends OQUsecase {
  CreateSubflagUsecase(this._repository);

  final IFlagRepository _repository;

  UsecaseResponse<Failure, SubflagOutput> call(SubflagCreateInput input) {
    return _repository.createSubflag(input);
  }
}
