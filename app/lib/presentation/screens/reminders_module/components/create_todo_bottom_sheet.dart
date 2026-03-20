import 'package:flutter/material.dart';
import 'package:organiq/modules/flags/data/models/flag_output.dart';
import 'package:organiq/modules/flags/data/models/subflag_output.dart';
import 'package:organiq/presentation/routes/app_navigation.dart';
import 'package:organiq/shared/components/oq_lib/index.dart';

class CreateTodoSheet extends StatefulWidget {
  const CreateTodoSheet({
    super.key,
    required this.loadingListenable,
    required this.errorListenable,
    required this.flagsListenable,
    required this.subflagsByFlagListenable,
    required this.onLoadSubflags,
    required this.onCreateTask,
    required this.pickTaskDate,
    required this.formatTaskDate,
  });

  final ValueNotifier<bool> loadingListenable;
  final ValueNotifier<String?> errorListenable;
  final ValueNotifier<List<FlagOutput>> flagsListenable;
  final ValueNotifier<Map<String, List<SubflagOutput>>>
  subflagsByFlagListenable;
  final Future<void> Function(String flagId) onLoadSubflags;
  final Future<bool> Function({
    required String title,
    String? description,
    DateTime? data,
    String? flagId,
    String? subflagId,
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
  late final ValueNotifier<String?> _selectedSubflagId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _dateNotifier = ValueNotifier<DateTime?>(null);
    _selectedFlagId = ValueNotifier<String?>(null);
    _selectedSubflagId = ValueNotifier<String?>(null);
    widget.flagsListenable.addListener(_handleFlagsChanged);
    widget.subflagsByFlagListenable.addListener(_handleSubflagsChanged);
  }

  @override
  void dispose() {
    widget.flagsListenable.removeListener(_handleFlagsChanged);
    widget.subflagsByFlagListenable.removeListener(_handleSubflagsChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    _dateNotifier.dispose();
    _selectedFlagId.dispose();
    _selectedSubflagId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.loadingListenable,
        widget.flagsListenable,
        widget.subflagsByFlagListenable,
        _selectedFlagId,
        _selectedSubflagId,
      ]),
      builder: (sheetContext, _) {
        final loading = widget.loadingListenable.value;
        final flags = widget.flagsListenable.value;
        final flagOptions = flags
            .map(
              (flag) => OQFlagsFieldOption(
                id: flag.id,
                label: flag.name,
                color: flag.color,
              ),
            )
            .toList(growable: false);
        final selectedFlagId = _selectedFlagId.value;
        final subflags = selectedFlagId == null
            ? const <SubflagOutput>[]
            : widget.subflagsByFlagListenable.value[selectedFlagId] ??
                  const <SubflagOutput>[];
        final subflagOptions = subflags
            .map(
              (subflag) => OQFlagsFieldOption(
                id: subflag.id,
                label: subflag.name,
                color: subflag.color,
              ),
            )
            .toList(growable: false);

        return OQBottomSheet(
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
              subflagId: _selectedSubflagId.value,
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
            OQSnackBar.error(sheetContext, message);
          },
          secondaryLabel: 'Cancelar',
          secondaryEnabled: !loading,
          onSecondaryPressed: () => _closeSheet(sheetContext),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OQTextField(
                label: 'Título',
                hint: 'Ex: Enviar proposta',
                controller: _titleController,
              ),
              const SizedBox(height: 12),
              OQTextField(
                label: 'Descrição',
                hint: 'Opcional',
                controller: _descriptionController,
                minLines: 3,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              OQFlagsField(
                options: flagOptions,
                selectedId: _selectedFlagId.value,
                enabled: !loading,
                onChanged: (value) async {
                  if (value == _selectedFlagId.value) return;
                  _selectedFlagId.value = value;
                  _selectedSubflagId.value = null;
                  if (value != null) {
                    await widget.onLoadSubflags(value);
                  }
                },
              ),
              if (_selectedFlagId.value != null) ...[
                const SizedBox(height: 12),
                OQFlagsField(
                  label: 'Subflag',
                  emptyLabel: 'Nenhuma subflag disponível',
                  options: subflagOptions,
                  selectedId: _selectedSubflagId.value,
                  enabled: !loading,
                  onChanged: (value) {
                    _selectedSubflagId.value = value;
                  },
                ),
              ],
              const SizedBox(height: 12),
              ValueListenableBuilder<DateTime?>(
                valueListenable: _dateNotifier,
                builder: (context, selectedDate, _) {
                  return OQDateField(
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
      _selectedSubflagId.value = null;
    }
  }

  void _handleSubflagsChanged() {
    final selectedFlagId = _selectedFlagId.value;
    final selectedSubflagId = _selectedSubflagId.value;
    if (selectedFlagId == null || selectedSubflagId == null) return;

    final subflags =
        widget.subflagsByFlagListenable.value[selectedFlagId] ?? const [];
    final stillExists = subflags.any((item) => item.id == selectedSubflagId);
    if (!stillExists) {
      _selectedSubflagId.value = null;
    }
  }

  void _closeSheet(BuildContext context) {
    return AppNavigation.pop(null, context);
  }
}
