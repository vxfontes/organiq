import 'package:flutter/material.dart';
import 'package:organiq/modules/inbox/data/models/create_suggestion_item.dart';
import 'package:organiq/presentation/screens/create_module/components/create_done_phase_view.dart';
import 'package:organiq/presentation/screens/create_module/components/create_edit_suggestion_sheet.dart';
import 'package:organiq/presentation/screens/create_module/components/create_input_phase_view.dart';
import 'package:organiq/presentation/screens/create_module/components/create_review_phase_view.dart';
import 'package:organiq/presentation/screens/create_module/controller/create_controller.dart';
import 'package:organiq/shared/components/ib_lib/index.dart';
import 'package:organiq/shared/state/ib_state.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends IBState<CreatePage, CreateController> {
  IBAIInputState _inputState = IBAIInputState.idle;

  @override
  void initState() {
    super.initState();
    controller.error.addListener(_onErrorChanged);
    controller.inputController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    controller.error.removeListener(_onErrorChanged);
    controller.inputController.removeListener(_onInputChanged);
    super.dispose();
  }

  void _onErrorChanged() {
    final error = controller.error.value;
    if (error != null && error.isNotEmpty && mounted) {
      IBSnackBar.error(context, error);
    }
  }

  void _onInputChanged() {
    final text = controller.inputController.text.trim();
    final loading = controller.loading.value;
    final voiceProcessing = controller.voiceProcessing.value;

    final nextState = switch ((loading, voiceProcessing, text.isEmpty)) {
      (true, _, _) || (_, true, _) => IBAIInputState.processing,
      (_, _, true) => IBAIInputState.idle,
      _ => IBAIInputState.typing,
    };

    if (!mounted || nextState == _inputState) {
      return;
    }

    setState(() => _inputState = nextState);
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty && _inputState != IBAIInputState.typing) {
      setState(() => _inputState = IBAIInputState.typing);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        controller.phase,
        controller.loading,
        controller.listening,
        controller.voiceProcessing,
        controller.voiceAvailable,
        controller.recordingSeconds,
        controller.processingLines,
        controller.suggestions,
        controller.batchResult,
      ]),
      builder: (context, _) {
        final phase = controller.phase.value;

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
    await IBBottomSheet.show(
      context: context,
      isAdaptive: true,
      child: CreateEditSuggestionSheet(
        suggestion: item,
        onSave: (edited) => controller.editSuggestion(index, edited),
      ),
    );
  }
}
