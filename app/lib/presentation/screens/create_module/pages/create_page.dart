import 'package:flutter/material.dart';
import 'package:organiq/modules/inbox/data/models/inbox_create_batch_result.dart';
import 'package:organiq/presentation/screens/create_module/components/create_result_line_tile.dart';
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

  void _showEditSheet(BuildContext context, CreateLineResult line) {
    final editController = TextEditingController(text: line.sourceText);

    IBBottomSheet.show(
      context: context,
      isFitWithContent: true,
      child: StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          var isLoading = false;
          return IBBottomSheet(
            title: 'Editar item',
            subtitle: 'Corrija o texto e reprocesse com a IA.',
            primaryLabel: 'Reprocessar',
            primaryLoading: isLoading,
            primaryEnabled: !isLoading,
            onPrimaryPressed: () async {
              final newText = editController.text.trim();
              if (newText.isEmpty) return;
              setSheetState(() => isLoading = true);
              Navigator.of(sheetContext).pop();
              await controller.editAndReprocessLine(line, newText);
            },
            secondaryLabel: 'Cancelar',
            onSecondaryPressed: () => Navigator.of(sheetContext).pop(),
            child: IBTextField(
              label: 'Texto original',
              hint: 'Ex: Reunião com time amanhã 14h',
              controller: editController,
              maxLines: 5,
              minLines: 3,
              keyboardType: TextInputType.multiline,
            ),
          );
        },
      ),
    ).then((_) => editController.dispose());
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
        controller.loading,
        controller.listening,
        controller.voiceProcessing,
        controller.voiceAvailable,
        controller.recordingSeconds,
        controller.batchResult,
      ]),
      builder: (context, _) {
        final loading = controller.loading.value;
        final listening = controller.listening.value;
        final voiceProcessing = controller.voiceProcessing.value;
        final voiceAvailable = controller.voiceAvailable.value;
        final recordingSeconds = controller.recordingSeconds.value;
        final batchResult = controller.batchResult.value;
        final inputLocked = loading || listening || voiceProcessing;

        return ColoredBox(
          color: AppColors.background,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      if (loading) ...[
                        const SizedBox(height: 12),
                        const IBAIPulseIndicator(
                          message: 'Processando seus itens...',
                          progress: null,
                        ),
                      ],
                      const SizedBox(height: 14),
                      _buildOrganizeButton(context, inputLocked, loading, voiceProcessing),
                      if (batchResult != null) ...[
                        const SizedBox(height: 24),
                        _buildSummary(context, batchResult),
                        const SizedBox(height: 16),
                        _buildResultsHeader(context, batchResult),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),
              if (batchResult != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final line = batchResult.lines[index];
                        return _buildResultItem(context, line);
                      },
                      childCount: batchResult.lines.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: IBText('Criar', context: context).titulo.build(),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.ai500, AppColors.ai600],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: AppColors.surface,
                  ),
                  const SizedBox(width: 4),
                  IBText('IA', context: context)
                      .caption
                      .color(AppColors.surface)
                      .build(),
                ],
              ),
            ),
          ],
        ),
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
          '$detectedItemsTotal itens detectados.',
      chips: [
        if (batchResult.tasksCount > 0)
          IBChip(
            label: 'Tarefas ${batchResult.tasksCount}',
            color: AppColors.primary700,
          ),
        if (batchResult.remindersCount > 0)
          IBChip(
            label: 'Lembretes ${batchResult.remindersCount}',
            color: AppColors.ai600,
          ),
        if (batchResult.eventsCount > 0)
          IBChip(
            label: 'Eventos ${batchResult.eventsCount}',
            color: AppColors.success600,
          ),
        if (batchResult.routinesCount > 0)
          IBChip(
            label: 'Cronograma ${batchResult.routinesCount}',
            color: AppColors.primary700,
          ),
        if (batchResult.shoppingListsCount > 0)
          IBChip(
            label: 'Lista de compras ${batchResult.shoppingListsCount}',
            color: AppColors.warning500,
          ),
        if (batchResult.shoppingItemsCount > 0)
          IBChip(
            label: 'Itens de compra ${batchResult.shoppingItemsCount}',
            color: AppColors.primary500,
          ),
        if (batchResult.failedCount > 0)
          IBChip(
            label: 'Falhas ${batchResult.failedCount}',
            color: AppColors.danger600,
          ),
      ],
    );
  }

  Widget _buildResultsHeader(BuildContext context, CreateBatchResult batchResult) {
    final visibleCount = batchResult.lines
        .where((l) => !l.confirmed && !l.deleted)
        .length;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.ai600.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            size: 16,
            color: AppColors.ai600,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: IBText(
            'Itens processados',
            context: context,
          ).subtitulo.build(),
        ),
        if (visibleCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IBText(
              '$visibleCount restante${visibleCount == 1 ? '' : 's'}',
              context: context,
            ).caption.color(AppColors.textMuted).build(),
          ),
      ],
    );
  }

  Widget _buildResultItem(BuildContext context, CreateLineResult line) {
    final type = _mapStatusToType(line.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: IBAIResultCard(
        title: line.message,
        subtitle: line.status == CreateLineStatus.failed ? line.message : null,
        type: type,
        sourceText: line.sourceText,
        isDeleting: line.deleting,
        isDeleted: line.deleted,
        isConfirmed: line.confirmed,
        onConfirm: () => controller.confirmLineResult(line),
        onEdit: () => _showEditSheet(context, line),
        onDismiss: line.canDelete ? () => controller.deleteLineResult(line) : null,
      ),
    );
  }

  IBAIResultType _mapStatusToType(CreateLineStatus status) {
    switch (status) {
      case CreateLineStatus.success:
        return IBAIResultType.task;
      case CreateLineStatus.failed:
        return IBAIResultType.failed;
    }
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
          _PulsingMicIcon(),
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

  String _formatRecordingTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }
}

class _PulsingMicIcon extends StatefulWidget {
  @override
  State<_PulsingMicIcon> createState() => _PulsingMicIconState();
}

class _PulsingMicIconState extends State<_PulsingMicIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

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
