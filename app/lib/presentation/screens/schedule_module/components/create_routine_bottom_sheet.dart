import 'package:flutter/material.dart';

import 'package:inbota/modules/flags/data/models/flag_output.dart';
import 'package:inbota/presentation/screens/schedule_module/controller/schedule_controller.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class CreateRoutineBottomSheet extends StatefulWidget {
  const CreateRoutineBottomSheet({
    super.key,
    required this.controller,
  });

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
        widget.controller.createSelectedWeekdays,
        widget.controller.createStartTime,
        widget.controller.createEndTime,
        widget.controller.createRecurrenceType,
        widget.controller.createSelectedFlagId,
      ]),
      builder: (context, _) {
        final isLoading = widget.controller.loading.value;
        final error = widget.controller.error.value;
        final flags = widget.controller.flags.value;
        final selectedWeekdays = widget.controller.createSelectedWeekdays.value;
        final startTime = widget.controller.createStartTime.value;
        final endTime = widget.controller.createEndTime.value;
        final recurrenceType = widget.controller.createRecurrenceType.value;
        final selectedFlagId = widget.controller.createSelectedFlagId.value;

        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
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
                IBText('Nova Rotina', context: context).titulo.build(),
                const SizedBox(height: 24),
                if (error != null && error.isNotEmpty) ...[
                  IBText(error, context: context)
                      .caption
                      .color(AppColors.danger600)
                      .build(),
                  const SizedBox(height: 16),
                ],
                IBTextField(
                  controller: widget.controller.createTitleController,
                  label: 'Título',
                  hint: 'Ex: Academia, Reunião, Tomar remédio',
                  enabled: !isLoading,
                ),
                const SizedBox(height: 20),
                IBText('Dias da semana', context: context).subtitulo.build(),
                const SizedBox(height: 12),
                _buildWeekdayChips(selectedWeekdays),
                const SizedBox(height: 20),
                _buildTimePickers(startTime, endTime),
                const SizedBox(height: 20),
                _buildRecurrenceDropdown(isLoading, recurrenceType),
                const SizedBox(height: 20),
                if (flags.isNotEmpty)
                  _buildFlagDropdown(flags, isLoading, selectedFlagId),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: IBButton(
                    label: isLoading ? 'Salvando...' : 'Criar rotina',
                    onPressed: isLoading ? null : _submit,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeekdayChips(Set<int> selectedWeekdays) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ScheduleController.weekdayChipOptions.map((day) {
        final value = day.value;
        final isSelected = selectedWeekdays.contains(value);

        return GestureDetector(
          onTap: () => widget.controller.toggleCreateWeekday(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary700 : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.primary700 : AppColors.border,
              ),
            ),
            child: Center(
              child: Text(
                day.label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimePickers(String startTime, String? endTime) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IBText('Início', context: context).caption.build(),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickStartTime,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 20, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Text(startTime,
                          style: const TextStyle(
                              fontSize: 16, color: AppColors.text)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IBText('Término (opcional)', context: context).caption.build(),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickEndTime,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 20, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Text(
                        endTime ?? '--:--',
                        style: TextStyle(
                            fontSize: 16,
                            color: endTime != null
                                ? AppColors.text
                                : AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecurrenceDropdown(bool isLoading, String recurrenceType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IBText('Frequência', context: context).caption.build(),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: recurrenceType,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'weekly', child: Text('Semanal')),
                DropdownMenuItem(value: 'biweekly', child: Text('Quinzenal')),
                DropdownMenuItem(value: 'triweekly', child: Text('3 em 3 semanas')),
                DropdownMenuItem(value: 'monthly_week', child: Text('Mensal (semana do mês)')),
              ],
              onChanged: isLoading
                  ? null
                  : (value) {
                      if (value != null) {
                        widget.controller.setCreateRecurrenceType(value);
                      }
                    },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlagDropdown(
    List<FlagOutput> flags,
    bool isLoading,
    String? selectedFlagId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IBText('Contexto (opcional)', context: context).caption.build(),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: selectedFlagId,
              isExpanded: true,
              hint: Text('Selecione um contexto',
                  style: TextStyle(color: AppColors.textMuted)),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('Nenhum')),
                ...flags.map((flag) => DropdownMenuItem(
                      value: flag.id,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: flag.color != null
                                  ? Color(int.parse(
                                      flag.color!.replaceFirst('#', '0xFF')))
                                  : AppColors.primary700,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(flag.name),
                        ],
                      ),
                    )),
              ],
              onChanged: isLoading
                  ? null
                  : (value) {
                      widget.controller.setCreateFlagId(value);
                    },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickStartTime() async {
    final parts = widget.controller.createStartTime.value.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (time != null) {
      widget.controller.setCreateStartTime(time);
    }
  }

  Future<void> _pickEndTime() async {
    final endTime = widget.controller.createEndTime.value;
    final initialTime = endTime != null
        ? TimeOfDay(
            hour: int.parse(endTime.split(':')[0]),
            minute: int.parse(endTime.split(':')[1]),
          )
        : TimeOfDay.now();

    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (time != null) {
      widget.controller.setCreateEndTime(time);
    }
  }

  Future<void> _submit() async {
    final success = await widget.controller.submitCreateRoutine();

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }
}
