import 'package:flutter_modular/flutter_modular.dart';
import 'package:organiq/modules/suggestions/data/repositories/suggestion_repository.dart';
import 'package:organiq/modules/suggestions/domain/repositories/i_suggestion_repository.dart';
import 'package:organiq/modules/suggestions/domain/usecases/accept_suggestion_block_usecase.dart';
import 'package:organiq/modules/suggestions/domain/usecases/get_conversation_usecase.dart';
import 'package:organiq/modules/suggestions/domain/usecases/send_suggestion_message_usecase.dart';

class SuggestionsModule {
  static void binds(Injector i) {
    i.addLazySingleton<ISuggestionRepository>(SuggestionRepository.new);
    i.addLazySingleton<SendSuggestionMessageUsecase>(
      SendSuggestionMessageUsecase.new,
    );
    i.addLazySingleton<AcceptSuggestionBlockUsecase>(
      AcceptSuggestionBlockUsecase.new,
    );
    i.addLazySingleton<GetConversationUsecase>(GetConversationUsecase.new);
  }
}
