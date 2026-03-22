import 'package:flutter/material.dart';
import 'package:organiq/modules/suggestions/data/models/accept_block_input.dart';
import 'package:organiq/modules/suggestions/data/models/suggestion_block.dart';
import 'package:organiq/modules/suggestions/data/models/suggestion_conversation_output.dart';
import 'package:organiq/modules/suggestions/data/models/suggestion_message_input.dart';
import 'package:organiq/modules/suggestions/domain/usecases/accept_suggestion_block_usecase.dart';
import 'package:organiq/modules/suggestions/domain/usecases/get_conversation_usecase.dart';
import 'package:organiq/modules/suggestions/domain/usecases/send_suggestion_message_usecase.dart';
import 'package:organiq/shared/state/oq_state.dart';

class SuggestionController implements OQController {
  SuggestionController(
    this._sendSuggestionMessageUsecase,
    this._acceptSuggestionBlockUsecase,
    this._getConversationUsecase,
  );

  final SendSuggestionMessageUsecase _sendSuggestionMessageUsecase;
  final AcceptSuggestionBlockUsecase _acceptSuggestionBlockUsecase;
  final GetConversationUsecase _getConversationUsecase;

  final TextEditingController inputController = TextEditingController();
  final ValueNotifier<List<SuggestionConversationMessageOutput>> messages =
      ValueNotifier(const <SuggestionConversationMessageOutput>[]);
  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);
  final ValueNotifier<String?> conversationId = ValueNotifier(null);
  final ValueNotifier<Set<String>> acceptedBlockIds = ValueNotifier(<String>{});
  final ValueNotifier<Set<String>> acceptingBlockIds = ValueNotifier(
    <String>{},
  );

  bool get hasMessages => messages.value.isNotEmpty;

  @override
  void dispose() {
    inputController.dispose();
    messages.dispose();
    loading.dispose();
    error.dispose();
    conversationId.dispose();
    acceptedBlockIds.dispose();
    acceptingBlockIds.dispose();
  }

  Future<bool> sendMessage() async {
    final text = inputController.text.trim();
    if (text.isEmpty || loading.value) return false;

    final localUserMessage = SuggestionConversationMessageOutput(
      id: 'local-user-${DateTime.now().microsecondsSinceEpoch}',
      role: 'user',
      content: text,
      createdAt: DateTime.now(),
    );

    messages.value = [...messages.value, localUserMessage];
    loading.value = true;
    error.value = null;

    final result = await _sendSuggestionMessageUsecase(
      SuggestionMessageInput(
        conversationId: conversationId.value,
        message: text,
      ),
    );

    loading.value = false;

    return result.fold(
      (failure) {
        error.value = failure.message ?? 'Não foi possível enviar a mensagem.';
        return false;
      },
      (output) {
        conversationId.value = output.conversationId;
        inputController.clear();

        final assistant = SuggestionConversationMessageOutput(
          id: output.messageId,
          role: 'assistant',
          content: output.text,
          createdAt: DateTime.now(),
          blocks: output.blocks,
        );
        messages.value = [...messages.value, assistant];
        return true;
      },
    );
  }

  Future<bool> acceptBlock(SuggestionBlock block) async {
    final blockId = block.id.trim();
    if (blockId.isEmpty) return false;
    if (acceptedBlockIds.value.contains(blockId)) return true;
    if (acceptingBlockIds.value.contains(blockId)) return false;

    acceptingBlockIds.value = {...acceptingBlockIds.value, blockId};
    error.value = null;

    final result = await _acceptSuggestionBlockUsecase(
      AcceptBlockInput.fromBlock(block),
    );

    acceptingBlockIds.value = {
      ...acceptingBlockIds.value.where((id) => id != blockId),
    };

    return result.fold(
      (failure) {
        error.value = failure.message ?? 'Não foi possível criar o item.';
        return false;
      },
      (_) {
        acceptedBlockIds.value = {...acceptedBlockIds.value, blockId};
        return true;
      },
    );
  }

  Future<bool> loadConversation(String id) async {
    final conversationRef = id.trim();
    if (conversationRef.isEmpty) return false;

    loading.value = true;
    error.value = null;

    final result = await _getConversationUsecase(conversationRef);
    loading.value = false;

    return result.fold(
      (failure) {
        error.value =
            failure.message ?? 'Não foi possível carregar a conversa.';
        return false;
      },
      (output) {
        conversationId.value = output.id;
        messages.value = output.messages;
        return true;
      },
    );
  }

  void resetConversation() {
    inputController.clear();
    messages.value = const <SuggestionConversationMessageOutput>[];
    acceptedBlockIds.value = <String>{};
    acceptingBlockIds.value = <String>{};
    conversationId.value = null;
    error.value = null;
  }
}
