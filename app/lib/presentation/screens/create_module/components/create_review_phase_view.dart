import 'package:flutter/material.dart';
import 'package:organiq/modules/inbox/data/models/create_suggestion_item.dart';
import 'package:organiq/presentation/screens/create_module/components/create_suggestion_card.dart';
import 'package:organiq/shared/components/ib_lib/index.dart';

class CreateReviewPhaseView extends StatelessWidget {
  const CreateReviewPhaseView({
    super.key,
    required this.confirming,
    required this.suggestions,
    required this.onGoBackToInput,
    required this.onConfirmAll,
    required this.onEditSuggestion,
    required this.onToggleSuggestionRemoval,
  });

  final bool confirming;
  final List<CreateSuggestionItem> suggestions;
  final VoidCallback onGoBackToInput;
  final VoidCallback onConfirmAll;
  final void Function(int index, CreateSuggestionItem item) onEditSuggestion;
  final ValueChanged<int> onToggleSuggestionRemoval;

  @override
  Widget build(BuildContext context) {
    final activeCount = suggestions.where((entry) => !entry.removed).length;
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
              onPressed: confirming ? null : onGoBackToInput,
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
        if (suggestions.isEmpty)
          IBCard(
            child: IBText(
              'Nenhuma sugestão disponível para revisão.',
              context: context,
            ).muted.build(),
          )
        else
          ...suggestions.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CreateSuggestionCard(
                suggestion: entry.value,
                onEdit: confirming
                    ? null
                    : () => onEditSuggestion(entry.key, entry.value),
                onRemove: confirming
                    ? null
                    : () => onToggleSuggestionRemoval(entry.key),
                onRestore: confirming
                    ? null
                    : () => onToggleSuggestionRemoval(entry.key),
              ),
            ),
          ),
        const SizedBox(height: 8),
        IBButton(
          label: confirmLabel,
          variant: IBButtonVariant.primary,
          onPressed: confirming ? null : onConfirmAll,
        ),
        const SizedBox(height: 8),
        IBButton(
          label: 'Voltar e editar texto',
          variant: IBButtonVariant.secondary,
          onPressed: confirming ? null : onGoBackToInput,
        ),
      ],
    );
  }
}
