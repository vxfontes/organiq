import 'package:flutter/material.dart';
import 'package:inbota/modules/flags/data/models/flag_output.dart';
import 'package:inbota/presentation/routes/app_navigation.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';

class CreateTodoSheet extends StatefulWidget {
  const CreateTodoSheet({
    super.key,
    required this.loadingListenable,
    required this.errorListenable,
    required this.flagsListenable,
    required this.onCreateTask,
    required this.pickTaskDate,
    required this.formatTaskDate,
  });

  final ValueNotifier<bool> loadingListenable;
  final ValueNotifier<String?> errorListenable;
  final ValueNotifier<List<FlagOutput>> flagsListenable;
  final Future<bool> Function({
    required String title,
    String? description,
    DateTime? data,
    String? flagId,
  })
  onCreateTask;
  final Future<DateTime?> Function(BuildContext context, DateTime? current)
  pickTaskDate;
  final String Function(DateTime? date) formatTaskDate;

  @override
  State<CreateTodoSheet> createState() => CreateTodoSheetState();
}

class CreateTodoSheetState extends State<CreateTodoSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final ValueNotifier<DateTime?> _dateNotifier;
  late final ValueNotifier<String?> _selectedFlagId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _dateNotifier = ValueNotifier<DateTime?>(null);
    _selectedFlagId = ValueNotifier<String?>(null);
    widget.flagsListenable.addListener(_handleFlagsChanged);
  }

  @override
  void dispose() {
    widget.flagsListenable.removeListener(_handleFlagsChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    _dateNotifier.dispose();
    _selectedFlagId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.loadingListenable,
        widget.flagsListenable,
        _selectedFlagId,
      ]),
      builder: (sheetContext, _) {
        final loading = widget.loadingListenable.value;
        final flags = widget.flagsListenable.value;
        final flagOptions = flags
            .map(
              (flag) => IBFlagsFieldOption(
                id: flag.id,
                label: flag.name,
                color: flag.color,
              ),
            )
            .toList(growable: false);
        return IBBottomSheet(
          title: 'Nova tarefa',
          primaryLabel: 'Adicionar',
          primaryLoading: loading,
          primaryEnabled: !loading,
          onPrimaryPressed: () async {
            final success = await widget.onCreateTask(
              title: _titleController.text,
              description: _descriptionController.text,
              data: _dateNotifier.value,
              flagId: _selectedFlagId.value,
            );
            if (!mounted) return;
            if (!sheetContext.mounted) return;
            if (success) {
              _closeSheet(sheetContext);
              return;
            }
            final message =
                widget.errorListenable.value ??
                'Não foi possível criar a tarefa.';
            IBSnackBar.error(sheetContext, message);
          },
          secondaryLabel: 'Cancelar',
          secondaryEnabled: !loading,
          onSecondaryPressed: () => _closeSheet(sheetContext),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IBTextField(
                label: 'Título',
                hint: 'Ex: Enviar proposta',
                controller: _titleController,
              ),
              const SizedBox(height: 12),
              IBTextField(
                label: 'Descrição',
                hint: 'Opcional',
                controller: _descriptionController,
                minLines: 3,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              IBFlagsField(
                options: flagOptions,
                selectedId: _selectedFlagId.value,
                enabled: !loading,
                onChanged: (value) {
                  _selectedFlagId.value = value;
                },
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<DateTime?>(
                valueListenable: _dateNotifier,
                builder: (context, selectedDate, _) {
                  return IBDateField(
                    valueLabel: widget.formatTaskDate(selectedDate),
                    enabled: !loading,
                    hasValue: selectedDate != null,
                    onTap: loading
                        ? null
                        : () async {
                            final next = await widget.pickTaskDate(
                              sheetContext,
                              selectedDate,
                            );
                            if (next != null) {
                              _dateNotifier.value = next;
                            }
                          },
                    onClear: loading ? null : () => _dateNotifier.value = null,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleFlagsChanged() {
    final selectedId = _selectedFlagId.value;
    if (selectedId == null) return;
    final stillExists = widget.flagsListenable.value.any(
      (flag) => flag.id == selectedId,
    );
    if (!stillExists) {
      _selectedFlagId.value = null;
    }
  }

  void _closeSheet(BuildContext context) {
    return AppNavigation.pop(null, context);
  }
}
