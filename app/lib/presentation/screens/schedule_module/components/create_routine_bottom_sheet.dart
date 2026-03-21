import 'package:flutter/material.dart';

import 'package:organiq/presentation/routes/app_navigation.dart';
import 'package:organiq/presentation/screens/schedule_module/controller/schedule_controller.dart';
import 'package:organiq/shared/components/oq_lib/index.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class CreateRoutineBottomSheet extends StatefulWidget {
  const CreateRoutineBottomSheet({super.key, required this.controller});

  final ScheduleController controller;

  @override
  State<CreateRoutineBottomSheet> createState() =>
      _CreateRoutineBottomSheetState();
}

class _CreateRoutineBottomSheetState extends State<CreateRoutineBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.controller.loading,
        widget.controller.error,
        widget.controller.flags,
        widget.controller.subflagsByFlag,
        widget.controller.createSelectedWeekdays,
        widget.controller.createStartTime,
        widget.controller.createEndTime,
        widget.controller.createRecurrenceType,
        widget.controller.createWeekOfMonth,
        widget.controller.createSelectedFlagId,
        widget.controller.createSelectedSubflagId,
      ]),
      builder: (sheetContext, _) {
        final isLoading = widget.controller.loading.value;
        final flags = widget.controller.flags.value;
        final flagOptions = flags
            .map(
              (flag) => OQFlagsFieldOption(
                id: flag.id,
                label: flag.name,
                color: flag.color,
              ),
            )
            .toList(growable: false);
        final selectedWeekdays = widget.controller.createSelectedWeekdays.value;
        final startTime = widget.controller.createStartTime.value;
        final endTime = widget.controller.createEndTime.value ?? '';
        final recurrenceType = widget.controller.createRecurrenceType.value;
        final isMonthlyDay = recurrenceType == 'monthly_day';
        final isMonthlyWeek = recurrenceType == 'monthly_week';
        final selectedWeekOfMonth = widget.controller.createWeekOfMonth.value;
        final selectedFlagId = widget.controller.createSelectedFlagId.value;
        final selectedSubflagId =
            widget.controller.createSelectedSubflagId.value;
        final subflags = selectedFlagId == null
            ? const []
            : widget.controller.subflagsByFlag.value[selectedFlagId] ??
                  const [];
        final subflagOptions = subflags
            .map(
              (subflag) => OQFlagsFieldOption(
                id: subflag.id,
                label: subflag.name,
                color: subflag.color,
              ),
            )
            .toList(growable: false);
        final title = widget.controller.formTitle;
        final primaryLabel = widget.controller.formPrimaryLabel;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              OQText(title, context: sheetContext).titulo.build(),
              const SizedBox(height: 24),
              OQTextField(
                controller: widget.controller.createTitleController,
                label: 'Título',
                hint: 'Ex: Academia, Reunião, Tomar remédio',
                enabled: !isLoading,
              ),
              const SizedBox(height: 20),
              _buildRecurrenceChips(sheetContext, isLoading, recurrenceType),
              if (isMonthlyWeek) ...[
                const SizedBox(height: 20),
                _buildWeekOfMonthChips(
                  sheetContext,
                  isLoading,
                  selectedWeekOfMonth,
                ),
              ],
              const SizedBox(height: 20),
              if (isMonthlyDay) ...[
                _buildDayOfMonthField(isLoading),
                const SizedBox(height: 20),
              ] else ...[
                OQText(
                  'Dias da semana',
                  context: sheetContext,
                ).subtitulo.build(),
                const SizedBox(height: 12),
                _buildWeekdayChips(
                  sheetContext,
                  selectedWeekdays,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 20),
              ],
              _buildTimePickers(
                sheetContext,
                startTime,
                endTime,
                enabled: !isLoading,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OQFlagsField(
                  label: 'Contexto Principal',
                  options: flagOptions,
                  selectedId: selectedFlagId,
                  enabled: !isLoading,
                  onChanged: (value) async {
                    if (value == selectedFlagId) return;
                    widget.controller.setCreateFlagId(value);
                    if (value != null) {
                      await widget.controller.loadSubflags(value);
                    }
                  },
                ),
              ),
              if (selectedFlagId != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OQFlagsField(
                    label: 'Sub-contexto',
                    emptyLabel: 'Nenhuma subflag disponível',
                    options: subflagOptions,
                    selectedId: selectedSubflagId,
                    enabled: !isLoading,
                    onChanged: widget.controller.setCreateSubflagId,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OQButton(
                  label: primaryLabel,
                  loading: isLoading,
                  onPressed: isLoading ? null : _submit,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeekdayChips(
    BuildContext chipContext,
    Set<int> selectedWeekdays, {
    required bool enabled,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ScheduleController.weekdayChipOptions.map((day) {
        final value = day.value;
        final isSelected = selectedWeekdays.contains(value);

        return InkWell(
          onTap: enabled
              ? () => widget.controller.toggleCreateWeekday(value)
              : null,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary700 : AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary700 : AppColors.border,
              ),
            ),
            child: Center(
              child: OQText(day.label, context: chipContext).label
                  .color(isSelected ? AppColors.surface : AppColors.text)
                  .build(),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimePickers(
    BuildContext pickerContext,
    String startTime,
    String endTime, {
    required bool enabled,
  }) {
    return Row(
      children: [
        Expanded(
          child: OQTimeField(
            label: 'Início',
            valueLabel: startTime,
            hasValue: true,
            enabled: enabled,
            onTap: _pickStartTime,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OQTimeField(
            label: 'Término',
            valueLabel: endTime.isEmpty ? '--:--' : endTime,
            hasValue: endTime.isNotEmpty,
            enabled: enabled,
            onTap: _pickEndTime,
          ),
        ),
      ],
    );
  }

  Widget _buildRecurrenceChips(
    BuildContext recurrenceContext,
    bool isLoading,
    String recurrenceType,
  ) {
    const options = [
      _RecurrenceOption('weekly', 'Semanal'),
      _RecurrenceOption('biweekly', 'Quinzenal'),
      _RecurrenceOption('triweekly', '3 em 3 semanas'),
      _RecurrenceOption('monthly_week', 'Mensal'),
      _RecurrenceOption('monthly_day', 'Mensal (dia)'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OQText('Frequência', context: recurrenceContext).caption.build(),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = option.value == recurrenceType;
            return OQChip(
              label: option.label,
              color: isSelected ? AppColors.primary700 : AppColors.textMuted,
              onTap: isLoading
                  ? null
                  : () =>
                        widget.controller.setCreateRecurrenceType(option.value),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWeekOfMonthChips(
    BuildContext context,
    bool isLoading,
    int? selectedWeekOfMonth,
  ) {
    const options = [
      (1, '1ª semana'),
      (2, '2ª semana'),
      (3, '3ª semana'),
      (4, '4ª semana'),
      (5, '5ª semana'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OQText('Semana do mês', context: context).caption.build(),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final week = option.$1;
            final label = option.$2;
            final isSelected = selectedWeekOfMonth == week;
            return OQChip(
              label: label,
              color: isSelected ? AppColors.primary700 : AppColors.textMuted,
              onTap: isLoading
                  ? null
                  : () => widget.controller.setCreateWeekOfMonth(week),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDayOfMonthField(bool isLoading) {
    return OQTextField(
      controller: widget.controller.createDayOfMonthController,
      label: 'Dia do mês',
      hint: 'Ex: 10',
      keyboardType: TextInputType.number,
      enabled: !isLoading,
      onChanged: (value) {
        final parsed = int.tryParse(value.trim());
        if (parsed == null) return;
        if (parsed < 1 || parsed > 31) return;
        widget.controller.setCreateDayOfMonth(parsed);
      },
    );
  }

  Future<void> _pickStartTime() async {
    final parts = widget.controller.createStartTime.value.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final time = await OQTimeField.pickTime(
      context,
      initialTime: initialTime,
      helpText: 'Horário de início',
    );

    if (time != null) {
      widget.controller.setCreateStartTime(time);
    }
  }

  Future<void> _pickEndTime() async {
    final endTime = widget.controller.createEndTime.value;
    final initialTime = endTime != null && endTime.isNotEmpty
        ? TimeOfDay(
            hour: int.parse(endTime.split(':')[0]),
            minute: int.parse(endTime.split(':')[1]),
          )
        : TimeOfDay.now();

    final time = await OQTimeField.pickTime(
      context,
      initialTime: initialTime,
      helpText: 'Horário de término',
    );

    if (time != null) {
      widget.controller.setCreateEndTime(time);
    }
  }

  Future<void> _submit() async {
    final success = await widget.controller.submitRoutineForm();

    if (!mounted) return;

    if (success) {
      AppNavigation.pop(null, context);
    } else {
      final error = widget.controller.error.value;
      if (error != null && error.isNotEmpty) {
        OQSnackBar.error(context, error);
      }
    }
  }
}

class _RecurrenceOption {
  const _RecurrenceOption(this.value, this.label);

  final String value;
  final String label;
}
