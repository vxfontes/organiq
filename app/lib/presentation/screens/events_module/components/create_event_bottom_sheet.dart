import 'package:flutter/material.dart';

import 'package:inbota/modules/flags/data/models/flag_output.dart';
import 'package:inbota/modules/flags/data/models/subflag_output.dart';
import 'package:inbota/presentation/routes/app_navigation.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/utils/reminders_format.dart';

class CreateEventBottomSheet extends StatefulWidget {
  const CreateEventBottomSheet({
    super.key,
    required this.loadingListenable,
    required this.errorListenable,
    required this.flagsListenable,
    required this.subflagsByFlagListenable,
    required this.onLoadSubflags,
    required this.onCreateEvent,
  });

  final ValueNotifier<bool> loadingListenable;
  final ValueNotifier<String?> errorListenable;
  final ValueNotifier<List<FlagOutput>> flagsListenable;
  final ValueNotifier<Map<String, List<SubflagOutput>>>
  subflagsByFlagListenable;
  final Future<void> Function(String flagId) onLoadSubflags;
  final Future<bool> Function({
    required String title,
    required DateTime? startAt,
    required DateTime? endAt,
    String? location,
    String? flagId,
    String? subflagId,
  })
  onCreateEvent;

  @override
  State<CreateEventBottomSheet> createState() => _CreateEventBottomSheetState();
}

class _CreateEventBottomSheetState extends State<CreateEventBottomSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final ValueNotifier<DateTime?> _startNotifier;
  late final ValueNotifier<DateTime?> _endNotifier;
  late final ValueNotifier<String?> _selectedFlagId;
  late final ValueNotifier<String?> _selectedSubflagId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _locationController = TextEditingController();
    _startNotifier = ValueNotifier<DateTime?>(null);
    _endNotifier = ValueNotifier<DateTime?>(null);
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
    _locationController.dispose();
    _startNotifier.dispose();
    _endNotifier.dispose();
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
        _startNotifier,
        _endNotifier,
        _selectedFlagId,
        _selectedSubflagId,
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

        final selectedFlagId = _selectedFlagId.value;
        final subflags = selectedFlagId == null
            ? const <SubflagOutput>[]
            : widget.subflagsByFlagListenable.value[selectedFlagId] ??
                  const <SubflagOutput>[];
        final subflagOptions = subflags
            .map(
              (subflag) => IBFlagsFieldOption(
                id: subflag.id,
                label: subflag.name,
                color: subflag.color,
              ),
            )
            .toList(growable: false);

        return IBBottomSheet(
          title: 'Novo evento',
          primaryLabel: 'Adicionar',
          primaryLoading: loading,
          primaryEnabled: !loading,
          onPrimaryPressed: () async {
            final success = await widget.onCreateEvent(
              title: _titleController.text,
              startAt: _startNotifier.value,
              endAt: _endNotifier.value,
              location: _locationController.text,
              flagId: _selectedFlagId.value,
              subflagId: _selectedSubflagId.value,
            );
            if (!mounted || !sheetContext.mounted) return;
            if (success) {
              _closeSheet(sheetContext);
              return;
            }
            final message =
                widget.errorListenable.value ??
                'Não foi possível criar o evento.';
            ScaffoldMessenger.of(
              sheetContext,
            ).showSnackBar(SnackBar(content: Text(message)));
          },
          secondaryLabel: 'Cancelar',
          secondaryEnabled: !loading,
          onSecondaryPressed: () => _closeSheet(sheetContext),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IBTextField(
                label: 'Título',
                hint: 'Ex: Reunião com cliente',
                controller: _titleController,
              ),
              const SizedBox(height: 12),
              IBTextField(
                label: 'Local (opcional)',
                hint: 'Ex: Google Meet',
                controller: _locationController,
              ),
              const SizedBox(height: 12),
              IBDateField(
                valueLabel: _formatEventDate(_startNotifier.value),
                enabled: !loading,
                hasValue: _startNotifier.value != null,
                onTap: loading
                    ? null
                    : () async {
                        final next = await IBDateField.pickDateTime(
                          sheetContext,
                          current: _startNotifier.value,
                          helpText: 'Selecionar início',
                        );
                        if (next != null) _startNotifier.value = next;
                      },
                onClear: loading ? null : () => _startNotifier.value = null,
                label: 'Início',
              ),
              const SizedBox(height: 12),
              IBDateField(
                valueLabel: _formatEventDate(_endNotifier.value),
                enabled: !loading,
                hasValue: _endNotifier.value != null,
                onTap: loading
                    ? null
                    : () async {
                        final next = await IBDateField.pickDateTime(
                          sheetContext,
                          current: _endNotifier.value ?? _startNotifier.value,
                          helpText: 'Selecionar fim',
                        );
                        if (next != null) _endNotifier.value = next;
                      },
                onClear: loading ? null : () => _endNotifier.value = null,
                label: 'Fim',
              ),
              const SizedBox(height: 12),
              IBFlagsField(
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
                IBFlagsField(
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
            ],
          ),
        );
      },
    );
  }

  String _formatEventDate(DateTime? date) {
    if (date == null) return 'Sem data definida';
    final day = RemindersFormat.formatDate(date);
    final hour = RemindersFormat.formatHour(date);
    return '$day às $hour';
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
