import 'package:flutter/material.dart';
import 'package:organiq/modules/inbox/data/models/create_suggestion_item.dart';
import 'package:organiq/shared/components/ib_lib/index.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class CreateSuggestionCard extends StatelessWidget {
  const CreateSuggestionCard({
    super.key,
    required this.suggestion,
    this.onEdit,
    this.onRemove,
    this.onRestore,
  });

  final CreateSuggestionItem suggestion;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final type = suggestion.resolvedType.trim().toLowerCase();
    final color = _typeColor(type);
    final confidence = suggestion.suggestion.confidence;

    final titleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: suggestion.removed ? AppColors.textMuted : AppColors.text,
      fontWeight: FontWeight.w600,
      decoration: suggestion.removed ? TextDecoration.lineThrough : null,
    );

    return Opacity(
      opacity: suggestion.removed ? 0.46 : 1,
      child: IBCard(
        padding: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      suggestion.resolvedTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IBChip(label: _typeLabel(type), color: color),
                ],
              ),
              const SizedBox(height: 8),
              IBText(
                'Origem: ${suggestion.sourceText}',
                context: context,
              ).caption.maxLines(2).build(),
              if (suggestion.suggestion.flag != null) ...[
                const SizedBox(height: 6),
                IBText(
                  'Flag: ${suggestion.suggestion.flag!.name}',
                  context: context,
                ).caption.build(),
              ],
              if (suggestion.suggestion.subflag != null) ...[
                const SizedBox(height: 2),
                IBText(
                  'Subflag: ${suggestion.suggestion.subflag!.name}',
                  context: context,
                ).caption.build(),
              ],
              if (confidence != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: confidence.clamp(0, 1),
                          minHeight: 6,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IBText(
                      '${(confidence * 100).round()}%',
                      context: context,
                    ).caption.weight(FontWeight.w600).build(),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!suggestion.removed) ...[
                    TextButton(
                      onPressed: onEdit,
                      child: IBText('Editar', context: context).label.build(),
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: onRemove,
                      child: IBText(
                        'Remover',
                        context: context,
                      ).label.color(AppColors.danger600).build(),
                    ),
                  ] else
                    TextButton(
                      onPressed: onRestore,
                      child: IBText(
                        'Restaurar',
                        context: context,
                      ).label.color(AppColors.ai600).build(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'task':
        return 'To-do';
      case 'reminder':
        return 'Lembrete';
      case 'event':
        return 'Evento';
      case 'routine':
        return 'Cronograma';
      case 'shopping':
        return 'Compras';
      default:
        return 'Item';
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'task':
        return AppColors.primary700;
      case 'reminder':
        return AppColors.ai600;
      case 'event':
        return AppColors.success600;
      case 'routine':
        return AppColors.primary700;
      case 'shopping':
        return AppColors.warning500;
      default:
        return AppColors.textMuted;
    }
  }
}
