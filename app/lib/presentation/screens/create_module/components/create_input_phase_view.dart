import 'package:flutter/material.dart';
import 'package:organiq/modules/inbox/data/models/create_processing_line.dart';
import 'package:organiq/modules/inbox/data/models/create_suggestion_item.dart';
import 'package:organiq/presentation/screens/create_module/components/create_page_header.dart';
import 'package:organiq/presentation/screens/create_module/components/create_processing_line_item.dart';
import 'package:organiq/presentation/screens/create_module/components/create_transcription_loading_card.dart';
import 'package:organiq/presentation/screens/create_module/components/create_voice_recording_card.dart';
import 'package:organiq/shared/components/oq_lib/index.dart';

class CreateInputPhaseView extends StatelessWidget {
  const CreateInputPhaseView({
    super.key,
    required this.processingMode,
    required this.inputController,
    required this.inputState,
    required this.loading,
    required this.listening,
    required this.voiceProcessing,
    required this.voiceAvailable,
    required this.recordingSeconds,
    required this.processingLines,
    required this.suggestions,
    required this.onToggleVoiceInput,
    required this.onProcessText,
    required this.onClearInput,
    required this.onTextChanged,
    required this.onReviewSuggestions,
    required this.onGoBackToInput,
  });

  final bool processingMode;
  final TextEditingController inputController;
  final OQAIInputState inputState;
  final bool loading;
  final bool listening;
  final bool voiceProcessing;
  final bool voiceAvailable;
  final int recordingSeconds;
  final List<CreateProcessingLine> processingLines;
  final List<CreateSuggestionItem> suggestions;
  final VoidCallback onToggleVoiceInput;
  final VoidCallback onProcessText;
  final VoidCallback onClearInput;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onReviewSuggestions;
  final VoidCallback onGoBackToInput;

  @override
  Widget build(BuildContext context) {
    final inputLocked =
        loading || listening || voiceProcessing || processingMode;

    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        const CreatePageHeader(),
        const SizedBox(height: 20),
        OQAIInputArea(
          controller: inputController,
          label: 'O que está na sua mente?',
          hint:
              'Ex:\n- Pagar aluguel dia 05\n- Reunião com time amanhã 14h\n- Comprar leite e café',
          onVoicePressed: () {
            if (!loading && !voiceProcessing) {
              onToggleVoiceInput();
            }
          },
          onSend: inputLocked ? null : onProcessText,
          onClear: inputLocked ? null : onClearInput,
          isSending: loading || voiceProcessing,
          inputState: inputState,
          isListening: listening,
          isVoiceAvailable: voiceAvailable,
          isLocked: inputLocked,
          onTextChanged: onTextChanged,
        ),
        if (listening) ...[
          const SizedBox(height: 12),
          CreateVoiceRecordingCard(recordingSeconds: recordingSeconds),
        ],
        if (voiceProcessing) ...[
          const SizedBox(height: 12),
          const CreateTranscriptionLoadingCard(),
        ],
        if (processingMode) ...[
          const SizedBox(height: 12),
          const OQAIPulseIndicator(
            message: 'Processando seus itens...',
            progress: null,
          ),
        ],
        if (!processingMode) ...[
          const SizedBox(height: 14),
          OQButton(
            label: 'Organizar',
            loading: loading || voiceProcessing,
            onPressed: inputLocked ? null : onProcessText,
          ),
        ],
        if (processingMode && processingLines.isNotEmpty) ...[
          const SizedBox(height: 12),
          _CreateProcessingCard(
            lines: processingLines,
            loading: loading,
            suggestions: suggestions,
            onReviewSuggestions: onReviewSuggestions,
            onGoBackToInput: onGoBackToInput,
          ),
        ],
      ],
    );
  }
}

class _CreateProcessingCard extends StatelessWidget {
  const _CreateProcessingCard({
    required this.lines,
    required this.loading,
    required this.suggestions,
    required this.onReviewSuggestions,
    required this.onGoBackToInput,
  });

  final List<CreateProcessingLine> lines;
  final bool loading;
  final List<CreateSuggestionItem> suggestions;
  final VoidCallback onReviewSuggestions;
  final VoidCallback onGoBackToInput;

  @override
  Widget build(BuildContext context) {
    final processedCount = lines
        .where(
          (line) =>
              line.status == LineProcessingStatus.done ||
              line.status == LineProcessingStatus.failed,
        )
        .length;

    return OQCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OQText(
            loading
                ? 'Processando $processedCount de ${lines.length} linhas...'
                : '$processedCount de ${lines.length} linhas processadas.',
            context: context,
          ).subtitulo.build(),
          const SizedBox(height: 10),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CreateProcessingLineItem(line: line),
            ),
          ),
          if (!loading && suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            OQButton(
              label: 'Revisar sugestões',
              variant: OQButtonVariant.primary,
              onPressed: onReviewSuggestions,
            ),
            const SizedBox(height: 8),
            OQButton(
              label: 'Voltar e editar texto',
              variant: OQButtonVariant.secondary,
              onPressed: onGoBackToInput,
            ),
          ],
        ],
      ),
    );
  }
}
