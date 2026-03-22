import 'package:dartz/dartz.dart';
import 'package:organiq/modules/suggestions/data/models/accept_block_input.dart';
import 'package:organiq/modules/suggestions/data/models/accept_block_output.dart';
import 'package:organiq/modules/suggestions/data/models/suggestion_conversation_output.dart';
import 'package:organiq/modules/suggestions/data/models/suggestion_message_input.dart';
import 'package:organiq/modules/suggestions/data/models/suggestion_message_output.dart';
import 'package:organiq/shared/errors/failures.dart';

abstract class ISuggestionRepository {
  Future<Either<Failure, SuggestionMessageOutput>> sendMessage(
    SuggestionMessageInput input,
  );

  Future<Either<Failure, AcceptBlockOutput>> acceptBlock(
    AcceptBlockInput input,
  );

  Future<Either<Failure, SuggestionConversationOutput>> getConversation(
    String id,
  );
}
