import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:organiq/modules/inbox/data/models/create_suggestion_item.dart';
import 'package:organiq/presentation/screens/create_module/components/create_ai_maintenance_view.dart';
import 'package:organiq/presentation/screens/create_module/components/create_mode_selector.dart';
import 'package:organiq/presentation/screens/create_module/components/create_done_phase_view.dart';
import 'package:organiq/presentation/screens/create_module/components/create_edit_suggestion_sheet.dart';
import 'package:organiq/presentation/screens/create_module/components/create_input_phase_view.dart';
import 'package:organiq/presentation/screens/create_module/components/create_review_phase_view.dart';
import 'package:organiq/presentation/screens/create_module/components/suggestion_chat_view.dart';
import 'package:organiq/presentation/screens/create_module/controller/create_controller.dart';
import 'package:organiq/presentation/screens/create_module/controller/suggestion_controller.dart';
import 'package:organiq/shared/components/oq_lib/index.dart';
import 'package:organiq/shared/state/oq_state.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends OQState<CreatePage, CreateController> {
  OQAIInputState _inputState = OQAIInputState.idle;
  late final SuggestionController _suggestionController;

  @override
  void initState() {
    super.initState();
    _suggestionController = Modular.get<SuggestionController>();
    controller.error.addListener(_onErrorChanged);
    _suggestionController.error.addListener(_onSuggestionErrorChanged);
    controller.inputController.addListener(_onInputChanged);
    controller.loadAIConfig();
  }

  @override
  void dispose() {
    controller.error.removeListener(_onErrorChanged);
    _suggestionController.error.removeListener(_onSuggestionErrorChanged);
    controller.inputController.removeListener(_onInputChanged);
    super.dispose();
  }

  void _onErrorChanged() {
    final error = controller.error.value;
    if (error != null && error.isNotEmpty && mounted) {
      OQSnackBar.error(context, error);
    }
  }

  void _onSuggestionErrorChanged() {
    final error = _suggestionController.error.value;
    if (error != null && error.isNotEmpty && mounted) {
      OQSnackBar.error(context, error);
    }
  }

  void _onInputChanged() {
    final text = controller.inputController.text.trim();
    final loading = controller.loading.value;
    final voiceProcessing = controller.voiceProcessing.value;

    final nextState = switch ((loading, voiceProcessing, text.isEmpty)) {
      (true, _, _) || (_, true, _) => OQAIInputState.processing,
      (_, _, true) => OQAIInputState.idle,
      _ => OQAIInputState.typing,
    };

    if (!mounted || nextState == _inputState) {
      return;
    }

    setState(() => _inputState = nextState);
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty && _inputState != OQAIInputState.typing) {
      setState(() => _inputState = OQAIInputState.typing);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        controller.createMode,
        controller.phase,
        controller.loading,
        controller.listening,
        controller.voiceProcessing,
        controller.voiceAvailable,
        controller.recordingSeconds,
        controller.processingLines,
        controller.suggestions,
        controller.batchResult,
        controller.createAiEnabled,
        controller.suggestionAiEnabled,
        _suggestionController.loading,
        _suggestionController.messages,
        _suggestionController.acceptedBlockIds,
        _suggestionController.acceptingBlockIds,
      ]),
      builder: (context, _) {
        final createMode = controller.createMode.value;
        final createAiEnabled = controller.createAiEnabled.value;
        final suggestionAiEnabled = controller.suggestionAiEnabled.value;
        final selectedModeDisabled =
            (createMode == 0 && !createAiEnabled) ||
            (createMode == 1 && !suggestionAiEnabled);
        final selectorEnabled =
            !controller.loading.value &&
            !controller.listening.value &&
            !controller.voiceProcessing.value &&
            !_suggestionController.loading.value;

        if (selectedModeDisabled) {
          return ColoredBox(
            color: AppColors.background,
            child: CreateAIMaintenanceView(
              mode: createMode,
              onModeChanged: controller.selectCreateMode,
              createAiEnabled: createAiEnabled,
              suggestionAiEnabled: suggestionAiEnabled,
              selectorEnabled: selectorEnabled,
            ),
          );
        }

        if (createMode == 1) {
          return ColoredBox(
            color: AppColors.background,
            child: SuggestionChatView(
              mode: createMode,
              onModeChanged: controller.selectCreateMode,
              messages: _suggestionController.messages.value,
              loading: _suggestionController.loading.value,
              inputController: _suggestionController.inputController,
              acceptedBlockIds: _suggestionController.acceptedBlockIds.value,
              acceptingBlockIds: _suggestionController.acceptingBlockIds.value,
              onSendMessage: _suggestionController.sendMessage,
              onResetConversation: _suggestionController.resetConversation,
              onAcceptBlock: _suggestionController.acceptBlock,
            ),
          );
        }

        final phase = controller.phase.value;
        final selector = CreateModeSelector(
          mode: createMode,
          onModeChanged: controller.selectCreateMode,
          enabled: selectorEnabled,
        );

        return ColoredBox(
          color: AppColors.background,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: switch (phase) {
              CreatePhase.input => CreateInputPhaseView(
                key: const ValueKey('create-input'),
                processingMode: false,
                inputController: controller.inputController,
                inputState: _inputState,
                loading: controller.loading.value,
                listening: controller.listening.value,
                voiceProcessing: controller.voiceProcessing.value,
                voiceAvailable: controller.voiceAvailable.value,
                recordingSeconds: controller.recordingSeconds.value,
                processingLines: controller.processingLines.value,
                suggestions: controller.suggestions.value,
                onToggleVoiceInput: controller.toggleVoiceInput,
                onProcessText: controller.processText,
                onClearInput: controller.clearInput,
                onTextChanged: _onTextChanged,
                onReviewSuggestions: controller.goToReview,
                onGoBackToInput: controller.goBackToInput,
                modeSelector: selector,
              ),
              CreatePhase.processing => CreateInputPhaseView(
                key: const ValueKey('create-processing'),
                processingMode: true,
                inputController: controller.inputController,
                inputState: _inputState,
                loading: controller.loading.value,
                listening: controller.listening.value,
                voiceProcessing: controller.voiceProcessing.value,
                voiceAvailable: controller.voiceAvailable.value,
                recordingSeconds: controller.recordingSeconds.value,
                processingLines: controller.processingLines.value,
                suggestions: controller.suggestions.value,
                onToggleVoiceInput: controller.toggleVoiceInput,
                onProcessText: controller.processText,
                onClearInput: controller.clearInput,
                onTextChanged: _onTextChanged,
                onReviewSuggestions: controller.goToReview,
                onGoBackToInput: controller.goBackToInput,
                modeSelector: selector,
              ),
              CreatePhase.review => CreateReviewPhaseView(
                key: const ValueKey('create-review'),
                confirming: false,
                suggestions: controller.suggestions.value,
                onGoBackToInput: controller.goBackToInput,
                onConfirmAll: controller.confirmAll,
                onEditSuggestion: (index, item) =>
                    _openEditSuggestionSheet(context, index: index, item: item),
                onToggleSuggestionRemoval: controller.toggleRemoveSuggestion,
              ),
              CreatePhase.confirming => CreateReviewPhaseView(
                key: const ValueKey('create-confirming'),
                confirming: true,
                suggestions: controller.suggestions.value,
                onGoBackToInput: controller.goBackToInput,
                onConfirmAll: controller.confirmAll,
                onEditSuggestion: (index, item) =>
                    _openEditSuggestionSheet(context, index: index, item: item),
                onToggleSuggestionRemoval: controller.toggleRemoveSuggestion,
              ),
              CreatePhase.done => CreateDonePhaseView(
                key: const ValueKey('create-done'),
                batchResult: controller.batchResult.value,
                onDeleteLineResult: controller.deleteLineResult,
                onRestart: controller.resetAll,
              ),
            },
          ),
        );
      },
    );
  }

  Future<void> _openEditSuggestionSheet(
    BuildContext context, {
    required int index,
    required CreateSuggestionItem item,
  }) async {
    await OQBottomSheet.show(
      context: context,
      isAdaptive: true,
      child: CreateEditSuggestionSheet(
        suggestion: item,
        onSave: (edited) => controller.editSuggestion(index, edited),
      ),
    );
  }
}
