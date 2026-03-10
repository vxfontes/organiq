import 'package:flutter/material.dart';
import 'package:inbota/modules/inbox/data/models/inbox_create_batch_result.dart';
import 'package:inbota/presentation/screens/create_module/components/create_result_line_tile.dart';
import 'package:inbota/presentation/screens/create_module/components/voice_react_wave_component.dart';
import 'package:inbota/presentation/screens/create_module/controller/create_controller.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/state/ib_state.dart';
import 'package:inbota/shared/theme/app_colors.dart';
import 'package:inbota/shared/utils/text_utils.dart';

class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends IBState<CreatePage, CreateController> {
  @override
  void initState() {
    super.initState();
    controller.error.addListener(_onErrorChanged);
  }

  @override
  void dispose() {
    controller.error.removeListener(_onErrorChanged);
    super.dispose();
  }

  void _onErrorChanged() {
    final error = controller.error.value;
    if (error != null && error.isNotEmpty && mounted) {
      IBSnackBar.error(context, error);
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              _buildHeader(context),
              const SizedBox(height: 14),
              IBCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    IBText(
                      'Descreva do seu jeito. Iremos processar e criar itens organizados para você.',
                      context: context,
                    ).muted.build(),
                    const SizedBox(height: 10),
                    IBTextField(
                      label: 'Como anda sua vida?',
                      hint:
                          'Ex:\n- Pagar aluguel dia 05\n- Reunião com time amanhã 14h\n- Comprar leite e cafe',
                      controller: controller.inputController,
                      readOnly: inputLocked,
                      suffixIcon: IconButton(
                        tooltip: listening
                            ? 'Parar transcrição'
                            : 'Transcrever por voz',
                        onPressed: (loading || voiceProcessing)
                            ? null
                            : controller.toggleVoiceInput,
                        icon: IBIcon(
                          listening
                              ? IBIcon.stopCircleRounded
                              : IBIcon.micRounded,
                          color: listening
                              ? AppColors.danger600
                              : (voiceAvailable
                                    ? AppColors.primary600
                                    : AppColors.textMuted),
                        ),
                      ),
                      minLines: 8,
                      maxLines: 10,
                    ),
                    if (listening) ...[
                      const SizedBox(height: 8),
                      _buildVoiceRecordingCard(context, recordingSeconds),
                    ],
                    if (voiceProcessing) ...[
                      const SizedBox(height: 8),
                      _buildTranscriptionLoadingCard(context),
                    ],
                    const SizedBox(height: 12),
                    IBButton(
                      label: 'Organizar',
                      loading: loading || voiceProcessing,
                      onPressed: inputLocked ? null : controller.processText,
                    ),
                    const SizedBox(height: 8),
                    IBButton(
                      label: 'Limpar',
                      variant: IBButtonVariant.secondary,
                      onPressed: inputLocked ? null : controller.clearInput,
                    ),
                  ],
                ),
              ),
              if (batchResult != null) ...[
                const SizedBox(height: 16),
                _buildSummary(context, batchResult),
                const SizedBox(height: 12),
                IBCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      IBText(
                        'Itens por linha',
                        context: context,
                      ).subtitulo.build(),
                      const SizedBox(height: 10),
                      ...batchResult.lines.map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: CreateResultLineTile(
                            result: line,
                            onDelete: controller.deleteLineResult,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
        IBText('Criar', context: context).titulo.build(),
        const SizedBox(height: 6),
        IBText(
          'Transforme texto em itens organizados: tarefas, lembretes, eventos e compras.',
          context: context,
        ).muted.build(),
      ],
    );
  }

  Widget _buildSummary(BuildContext context, CreateBatchResult batchResult) {
    final processedLabel = TextUtils.countLabel(
      batchResult.totalInputs,
      'linha processada',
      'linhas processadas',
    );

    return IBOverviewCard(
      title: 'Resumo',
      subtitle:
          '${batchResult.successCount} de $processedLabel. Revise abaixo.',
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

  Widget _buildVoiceRecordingCard(BuildContext context, int recordingSeconds) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary200),
      ),
      child: Row(
        children: [
          const IBIcon(IBIcon.micRounded, color: AppColors.danger600, size: 18),
          const SizedBox(width: 8),
          IBText(
            'Gravando ${_formatRecordingTime(recordingSeconds)}',
            context: context,
          ).caption.color(AppColors.primary700).build(),
          const SizedBox(width: 10),
          const Expanded(child: VoiceReactiveWave(color: AppColors.primary600)),
        ],
      ),
    );
  }

  Widget _buildTranscriptionLoadingCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
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
