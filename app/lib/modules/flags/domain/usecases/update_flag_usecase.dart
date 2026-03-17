import 'package:organiq/modules/flags/data/models/flag_output.dart';
import 'package:organiq/modules/flags/data/models/flag_update_input.dart';
import 'package:organiq/modules/flags/domain/repositories/i_flag_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/oq_usecase.dart';

class UpdateFlagUsecase extends OQUsecase {
  UpdateFlagUsecase(this._repository);

  final IFlagRepository _repository;

  UsecaseResponse<Failure, FlagOutput> call(FlagUpdateInput input) {
    return _repository.updateFlag(input);
  }
}
