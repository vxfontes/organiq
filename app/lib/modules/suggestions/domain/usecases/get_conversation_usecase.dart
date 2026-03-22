import 'package:organiq/modules/suggestions/data/models/suggestion_conversation_output.dart';
import 'package:organiq/modules/suggestions/domain/repositories/i_suggestion_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/oq_usecase.dart';

class GetConversationUsecase extends OQUsecase {
  GetConversationUsecase(this._repository);

  final ISuggestionRepository _repository;

  UsecaseResponse<Failure, SuggestionConversationOutput> call(String id) {
    return _repository.getConversation(id);
  }
}
