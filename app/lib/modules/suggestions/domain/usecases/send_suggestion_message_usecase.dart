import 'package:organiq/modules/suggestions/data/models/suggestion_message_input.dart';
import 'package:organiq/modules/suggestions/data/models/suggestion_message_output.dart';
import 'package:organiq/modules/suggestions/domain/repositories/i_suggestion_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/oq_usecase.dart';

class SendSuggestionMessageUsecase extends OQUsecase {
  SendSuggestionMessageUsecase(this._repository);

  final ISuggestionRepository _repository;

  UsecaseResponse<Failure, SuggestionMessageOutput> call(
    SuggestionMessageInput input,
  ) {
    return _repository.sendMessage(input);
  }
}
