import 'package:organiq/modules/flags/data/models/flag_create_input.dart';
import 'package:organiq/modules/flags/data/models/flag_output.dart';
import 'package:organiq/modules/flags/domain/repositories/i_flag_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/oq_usecase.dart';

class CreateFlagUsecase extends OQUsecase {
  CreateFlagUsecase(this._repository);

  final IFlagRepository _repository;

  UsecaseResponse<Failure, FlagOutput> call(FlagCreateInput input) {
    return _repository.createFlag(input);
  }
}
