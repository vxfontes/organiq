import 'package:organiq/modules/suggestions/data/models/accept_block_input.dart';
import 'package:organiq/modules/suggestions/data/models/accept_block_output.dart';
import 'package:organiq/modules/suggestions/domain/repositories/i_suggestion_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/oq_usecase.dart';

class AcceptSuggestionBlockUsecase extends OQUsecase {
  AcceptSuggestionBlockUsecase(this._repository);

  final ISuggestionRepository _repository;

  UsecaseResponse<Failure, AcceptBlockOutput> call(AcceptBlockInput input) {
    return _repository.acceptBlock(input);
  }
}
