import 'package:flutter/material.dart';
import 'package:organiq/modules/inbox/data/models/create_suggestion_item.dart';
import 'package:organiq/shared/components/ib_lib/index.dart';

class CreateEditSuggestionSheet extends StatefulWidget {
  const CreateEditSuggestionSheet({
    super.key,
    required this.suggestion,
    required this.onSave,
  });

  final CreateSuggestionItem suggestion;
  final ValueChanged<CreateSuggestionItem> onSave;

  @override
  State<CreateEditSuggestionSheet> createState() =>
      _CreateEditSuggestionSheetState();
}

class _CreateEditSuggestionSheetState extends State<CreateEditSuggestionSheet> {
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.suggestion.resolvedTitle,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typeLabel = _typeLabel(widget.suggestion.resolvedType);

    return IBBottomSheet(
      title: 'Editar sugestão',
      subtitle:
          'Ajuste o título antes de confirmar. A edição de payload será adicionada no próximo passo.',
      primaryLabel: 'Salvar alterações',
      onPrimaryPressed: _onSave,
      secondaryLabel: 'Cancelar',
      onSecondaryPressed: () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IBText('Tipo', context: context).label.build(),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: IBChip(label: typeLabel),
          ),
          const SizedBox(height: 14),
          IBTextField(
            label: 'Título',
            controller: _titleController,
            minLines: 1,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  void _onSave() {
    final editedTitle = _titleController.text.trim();
    final originalTitle = widget.suggestion.suggestion.title.trim();

    final next = CreateSuggestionItem(
      sourceText: widget.suggestion.sourceText,
      inboxItemId: widget.suggestion.inboxItemId,
      suggestion: widget.suggestion.suggestion,
      removed: widget.suggestion.removed,
      editedTitle: editedTitle.isNotEmpty && editedTitle != originalTitle
          ? editedTitle
          : null,
      editedType: widget.suggestion.editedType,
      editedPayload: widget.suggestion.editedPayload,
      editedFlagId: widget.suggestion.editedFlagId,
      editedSubflagId: widget.suggestion.editedSubflagId,
    );

    widget.onSave(next);
    Navigator.of(context).pop();
  }

  String _typeLabel(String type) {
    switch (type.trim().toLowerCase()) {
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
}
