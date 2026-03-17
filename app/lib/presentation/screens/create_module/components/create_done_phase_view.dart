import 'package:flutter/material.dart';
import 'package:organiq/modules/inbox/data/models/inbox_create_batch_result.dart';
import 'package:organiq/modules/inbox/data/models/inbox_create_line_result.dart';
import 'package:organiq/presentation/screens/create_module/components/create_page_header.dart';
import 'package:organiq/presentation/screens/create_module/components/create_result_line_tile.dart';
import 'package:organiq/shared/components/ib_lib/index.dart';
import 'package:organiq/shared/theme/app_colors.dart';
import 'package:organiq/shared/utils/text_utils.dart';

class CreateDonePhaseView extends StatelessWidget {
  const CreateDonePhaseView({
    super.key,
    required this.batchResult,
    required this.onDeleteLineResult,
    required this.onRestart,
  });

  final CreateBatchResult? batchResult;
  final Future<bool> Function(CreateLineResult result)? onDeleteLineResult;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        const CreatePageHeader(),
        const SizedBox(height: 20),
        if (batchResult == null)
          IBCard(
            child: IBText(
              'Nenhum resultado para mostrar.',
              context: context,
            ).muted.build(),
          )
        else ...[
          _buildSummary(context, batchResult!),
          const SizedBox(height: 16),
          _buildResultsHeader(context, batchResult!),
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
                ...batchResult!.lines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CreateResultLineTile(
                      result: line,
                      onDelete: onDeleteLineResult,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRestart,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              backgroundColor: AppColors.primary700,
              foregroundColor: AppColors.surface,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const IBIcon(
                  IBIcon.autoAwesomeRounded,
                  color: AppColors.surface,
                  size: 18,
                ),
                const SizedBox(width: 8),
                IBText(
                  'Criar mais',
                  context: context,
                ).label.color(AppColors.surface).build(),
              ],
            ),
          ),
        ],
      ],
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
}
