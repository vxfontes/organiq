import 'package:organiq/modules/flags/data/models/subflag_output.dart';
import 'package:organiq/modules/flags/data/models/subflag_update_input.dart';
import 'package:organiq/modules/flags/domain/repositories/i_flag_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/ib_usecase.dart';

class UpdateSubflagUsecase extends IBUsecase {
  UpdateSubflagUsecase(this._repository);

  final IFlagRepository _repository;

  UsecaseResponse<Failure, SubflagOutput> call(SubflagUpdateInput input) {
    return _repository.updateSubflag(input);
  }
}
