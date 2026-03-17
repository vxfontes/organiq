import 'package:organiq/modules/flags/data/models/subflag_list_output.dart';
import 'package:organiq/modules/flags/domain/repositories/i_flag_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/ib_usecase.dart';

class GetSubflagsByFlagUsecase extends IBUsecase {
  GetSubflagsByFlagUsecase(this._repository);

  final IFlagRepository _repository;

  UsecaseResponse<Failure, SubflagListOutput> call({
    required String flagId,
    int? limit,
    String? cursor,
  }) {
    return _repository.fetchSubflagsByFlag(
      flagId: flagId,
      limit: limit,
      cursor: cursor,
    );
  }
}
