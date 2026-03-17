import 'package:organiq/modules/flags/data/models/flag_list_output.dart';
import 'package:organiq/modules/flags/domain/repositories/i_flag_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/oq_usecase.dart';

class GetFlagsUsecase extends OQUsecase {
  final IFlagRepository _repository;

  GetFlagsUsecase(this._repository);

  UsecaseResponse<Failure, FlagListOutput> call({int? limit, String? cursor}) {
    return _repository.fetchFlags(limit: limit, cursor: cursor);
  }
}
