import 'package:flutter/material.dart';
import 'package:organiq/modules/inbox/data/models/create_processing_line.dart';
import 'package:organiq/modules/inbox/data/models/create_suggestion_item.dart';
import 'package:organiq/modules/inbox/data/models/inbox_create_batch_result.dart';
import 'package:organiq/presentation/screens/create_module/components/create_edit_suggestion_sheet.dart';
import 'package:organiq/presentation/screens/create_module/components/create_processing_line_item.dart';
import 'package:organiq/presentation/screens/create_module/components/create_result_line_tile.dart';
import 'package:organiq/presentation/screens/create_module/components/create_suggestion_card.dart';
import 'package:organiq/presentation/screens/create_module/components/voice_react_wave_component.dart';
import 'package:organiq/presentation/screens/create_module/controller/create_controller.dart';
import 'package:organiq/shared/components/ib_lib/index.dart';
import 'package:organiq/shared/state/ib_state.dart';
import 'package:organiq/shared/theme/app_colors.dart';
import 'package:organiq/shared/utils/text_utils.dart';

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

    if (loading || voiceProcessing) {
      setState(() => _inputState = IBAIInputState.processing);
    } else if (text.isEmpty) {
      setState(() => _inputState = IBAIInputState.idle);
    } else {
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
              CreatePhase.input => _buildInputPhase(
                context,
                key: const ValueKey('create-input'),
                processingMode: false,
              ),
              CreatePhase.processing => _buildInputPhase(
                context,
                key: const ValueKey('create-processing'),
                processingMode: true,
              ),
              CreatePhase.review => _buildReviewPhase(
                context,
                key: const ValueKey('create-review'),
                confirming: false,
              ),
              CreatePhase.confirming => _buildReviewPhase(
                context,
                key: const ValueKey('create-confirming'),
                confirming: true,
              ),
              CreatePhase.done => _buildDonePhase(
                context,
                key: const ValueKey('create-done'),
              ),
            },
          ),
        );
      },
    );
  }

  Widget _buildInputPhase(
    BuildContext context, {
    required Key key,
    required bool processingMode,
  }) {
    final loading = controller.loading.value;
    final listening = controller.listening.value;
    final voiceProcessing = controller.voiceProcessing.value;
    final voiceAvailable = controller.voiceAvailable.value;
    final recordingSeconds = controller.recordingSeconds.value;
    final inputLocked =
        loading || listening || voiceProcessing || processingMode;

    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        _buildHeader(context),
        const SizedBox(height: 20),
        _buildAIInputSection(
          context,
          inputLocked,
          listening,
          voiceAvailable,
          loading,
          voiceProcessing,
        ),
        if (listening) ...[
          const SizedBox(height: 12),
          _buildVoiceRecordingCard(context, recordingSeconds),
        ],
        if (voiceProcessing) ...[
          const SizedBox(height: 12),
          _buildTranscriptionLoadingCard(context),
        ],
        if (processingMode) ...[
          const SizedBox(height: 12),
          const IBAIPulseIndicator(
            message: 'Processando seus itens...',
            progress: null,
          ),
        ],
        if (!processingMode) ...[
          const SizedBox(height: 14),
          _buildOrganizeButton(context, inputLocked, loading, voiceProcessing),
        ],
        if (processingMode && controller.processingLines.value.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildProcessingCard(context),
        ],
      ],
    );
  }

  Widget _buildReviewPhase(
    BuildContext context, {
    required Key key,
    required bool confirming,
  }) {
    final list = controller.suggestions.value;
    final activeCount = list.where((entry) => !entry.removed).length;
    final confirmLabel = activeCount > 0
        ? 'Confirmar todos ($activeCount)'
        : 'Finalizar';

    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: confirming ? null : controller.goBackToInput,
              icon: const IBIcon(IBIcon.arrowBackRounded),
              tooltip: 'Voltar',
            ),
            const SizedBox(width: 2),
            Expanded(
              child: IBText(
                'Revisar sugestões',
                context: context,
              ).titulo.build(),
            ),
          ],
        ),
        const SizedBox(height: 6),
        IBText(
          'Verifique e ajuste antes de confirmar.',
          context: context,
        ).muted.build(),
        const SizedBox(height: 12),
        if (list.isEmpty)
          IBCard(
            child: IBText(
              'Nenhuma sugestão disponível para revisão.',
              context: context,
            ).muted.build(),
          )
        else
          ...list.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CreateSuggestionCard(
                suggestion: entry.value,
                onEdit: confirming
                    ? null
                    : () => _openEditSuggestionSheet(
                        context,
                        index: entry.key,
                        item: entry.value,
                      ),
                onRemove: confirming
                    ? null
                    : () => controller.toggleRemoveSuggestion(entry.key),
                onRestore: confirming
                    ? null
                    : () => controller.toggleRemoveSuggestion(entry.key),
              ),
            ),
          ),
        const SizedBox(height: 8),
        IBButton(
          label: confirmLabel,
          variant: IBButtonVariant.primary,
          onPressed: confirming ? null : controller.confirmAll,
        ),
        const SizedBox(height: 8),
        IBButton(
          label: 'Voltar e editar texto',
          variant: IBButtonVariant.secondary,
          onPressed: confirming ? null : controller.goBackToInput,
        ),
      ],
    );
  }

  Widget _buildDonePhase(BuildContext context, {required Key key}) {
    final batchResult = controller.batchResult.value;

    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        _buildHeader(context),
        const SizedBox(height: 20),
        if (batchResult == null)
          IBCard(
            child: IBText(
              'Nenhum resultado para mostrar.',
              context: context,
            ).muted.build(),
          )
        else ...[
          _buildSummary(context, batchResult),
          const SizedBox(height: 16),
          _buildResultsHeader(context, batchResult),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.dark.withAlpha(8),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...batchResult.lines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CreateResultLineTile(
                      result: line,
                      onDelete: controller.deleteLineResult,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildRestartButton(
            context,
            label: 'Criar mais',
            icon: IBIcon.autoAwesomeRounded,
            onPressed: controller.resetAll,
          ),
        ],
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IBText('Criar', context: context).titulo.build(),
        const SizedBox(height: 6),
        IBText(
          'Transforme texto em itens organizados: tarefas, lembretes, eventos e compras.',
          context: context,
        ).muted.build(),
      ],
    );
  }

  Widget _buildAIInputSection(
    BuildContext context,
    bool inputLocked,
    bool listening,
    bool voiceAvailable,
    bool loading,
    bool voiceProcessing,
  ) {
    return IBAIInputArea(
      controller: controller.inputController,
      label: 'O que está na sua mente?',
      hint:
          'Ex:\n- Pagar aluguel dia 05\n- Reunião com time amanhã 14h\n- Comprar leite e café',
      onVoicePressed: () {
        if (!loading && !voiceProcessing) {
          controller.toggleVoiceInput();
        }
      },
      onSend: inputLocked ? null : controller.processText,
      onClear: inputLocked ? null : controller.clearInput,
      isSending: loading || voiceProcessing,
      inputState: _inputState,
      isListening: listening,
      isVoiceAvailable: voiceAvailable,
      isLocked: inputLocked,
      onTextChanged: (text) {
        if (text.isNotEmpty) {
          setState(() => _inputState = IBAIInputState.typing);
        }
      },
    );
  }

  Widget _buildOrganizeButton(
    BuildContext context,
    bool inputLocked,
    bool loading,
    bool voiceProcessing,
  ) {
    return IBButton(
      label: 'Organizar',
      loading: loading || voiceProcessing,
      onPressed: inputLocked ? null : controller.processText,
    );
  }

  Widget _buildSummary(BuildContext context, CreateBatchResult batchResult) {
    final processedLabel = TextUtils.countLabel(
      batchResult.totalInputs,
      'linha processada',
      'linhas processadas',
    );
    final detectedItemsTotal =
        batchResult.tasksCount +
        batchResult.remindersCount +
        batchResult.eventsCount +
        batchResult.routinesCount +
        batchResult.shoppingListsCount;

    return IBOverviewCard(
      title: 'Resumo',
      subtitle:
          '${batchResult.successCount} de $processedLabel. '
          '$detectedItemsTotal itens criados.',
      chips: [
        IBChip(
          label: 'Tarefas ${batchResult.tasksCount}',
          color: AppColors.primary700,
        ),
        IBChip(
          label: 'Lembretes ${batchResult.remindersCount}',
          color: AppColors.ai600,
        ),
        IBChip(
          label: 'Eventos ${batchResult.eventsCount}',
          color: AppColors.success600,
        ),
        IBChip(
          label: 'Cronograma ${batchResult.routinesCount}',
          color: AppColors.primary700,
        ),
        IBChip(
          label: 'Lista de compras ${batchResult.shoppingListsCount}',
          color: AppColors.warning500,
        ),
        IBChip(
          label: 'Itens de compra ${batchResult.shoppingItemsCount}',
          color: AppColors.primary500,
        ),
        IBChip(
          label: 'Falhas ${batchResult.failedCount}',
          color: AppColors.danger600,
        ),
      ],
    );
  }

  Widget _buildResultsHeader(
    BuildContext context,
    CreateBatchResult batchResult,
  ) {
    final visibleCount = batchResult.lines
        .where((line) => !line.deleted)
        .length;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            size: 16,
            color: AppColors.primary700,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IBText('Itens processados', context: context).subtitulo.build(),
              const SizedBox(height: 2),
              IBText(
                'Revise o que foi criado a partir do seu texto.',
                context: context,
              ).caption.build(),
            ],
          ),
        ),
        if (visibleCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: IBText(
              '$visibleCount restante${visibleCount == 1 ? '' : 's'}',
              context: context,
            ).caption.color(AppColors.textMuted).build(),
          ),
      ],
    );
  }

  Widget _buildProcessingCard(BuildContext context) {
    final lines = controller.processingLines.value;
    final loading = controller.loading.value;
    final suggestions = controller.suggestions.value;

    final processedCount = lines
        .where(
          (line) =>
              line.status == LineProcessingStatus.done ||
              line.status == LineProcessingStatus.failed,
        )
        .length;

    return IBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IBText(
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
            IBButton(
              label: 'Revisar sugestões',
              variant: IBButtonVariant.primary,
              onPressed: controller.goToReview,
            ),
            const SizedBox(height: 8),
            IBButton(
              label: 'Voltar e editar texto',
              variant: IBButtonVariant.secondary,
              onPressed: controller.goBackToInput,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRestartButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: AppColors.primary700,
        foregroundColor: AppColors.surface,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IBIcon(icon, color: AppColors.surface, size: 18),
          const SizedBox(width: 8),
          IBText(
            label,
            context: context,
          ).label.color(AppColors.surface).build(),
        ],
      ),
    );
  }

  Widget _buildVoiceRecordingCard(BuildContext context, int recordingSeconds) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.danger600.withAlpha((0.08 * 255).round()),
            AppColors.primary50,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.danger600.withAlpha((0.3 * 255).round()),
        ),
      ),
      child: Row(
        children: [
          const _PulsingMicIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IBText(
                  'Gravando',
                  context: context,
                ).label.color(AppColors.danger600).build(),
                const SizedBox(height: 2),
                IBText(
                  _formatRecordingTime(recordingSeconds),
                  context: context,
                ).caption.color(AppColors.textMuted).build(),
              ],
            ),
          ),
          const SizedBox(
            width: 60,
            height: 24,
            child: VoiceReactiveWave(color: AppColors.primary600),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptionLoadingCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          IBText(
            'Transcrevendo áudio...',
            context: context,
          ).caption.color(AppColors.textMuted).build(),
        ],
      ),
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

  String _formatRecordingTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }
}

class _PulsingMicIcon extends StatefulWidget {
  const _PulsingMicIcon();

  @override
  State<_PulsingMicIcon> createState() => _PulsingMicIconState();
}

class _PulsingMicIconState extends State<_PulsingMicIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.danger600.withAlpha(
              ((0.1 + (_controller.value * 0.1)) * 255).round(),
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mic_rounded,
            color: AppColors.danger600,
            size: 20,
          ),
        );
      },
    );
  }
}
