import 'package:flutter/material.dart';

import 'package:inbota/modules/routines/data/models/routine_output.dart';
import 'package:inbota/modules/routines/data/models/routine_section.dart';
import 'package:inbota/presentation/screens/schedule_module/components/create_routine_bottom_sheet.dart';
import 'package:inbota/presentation/screens/schedule_module/controller/schedule_controller.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/state/ib_state.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends IBState<SchedulePage, ScheduleController> {
  @override
  void initState() {
    super.initState();
    controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        controller.loading,
        controller.error,
        controller.routinesByPeriod,
        controller.selectedWeekday,
        controller.selectedWeekOffset,
      ]),
      builder: (context, _) {
        final error = controller.error.value;
        final selectedWeekdayIndex = controller.selectedWeekdayIndex;
        final routineSections = controller.routineSections;

        return Stack(
          children: [
            ColoredBox(
              color: AppColors.background,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  _buildHeader(context),
                  if (error != null && error.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    IBText(error, context: context)
                        .caption
                        .color(AppColors.danger600)
                        .build(),
                  ],
                  const SizedBox(height: 16),
                  _buildWeekSelector(),
                  const SizedBox(height: 20),
                  _buildWeekdayTabs(selectedWeekdayIndex),
                  const SizedBox(height: 20),
                  _buildRoutineList(routineSections),
                ],
              ),
            ),
            if (controller.shouldShowLoadingOverlay)
              const Positioned.fill(
                child: ColoredBox(
                  color: AppColors.background,
                  child: Center(child: IBLoader(label: 'Carregando...')),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IBText('Cronograma', context: context).titulo.build(),
              const SizedBox(height: 6),
              IBText(
                'Suas rotinas semanais',
                context: context,
              ).muted.build(),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Adicionar rotina',
          onPressed: _openCreateRoutine,
          icon: const IBIcon(
            IBIcon.addRounded,
            color: AppColors.primary700,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekSelector() {
    return Row(
      children: [
        _buildWeekButton('Esta semana', 0),
        const SizedBox(width: 8),
        _buildWeekButton('Próxima semana', 1),
      ],
    );
  }

  Widget _buildWeekButton(String label, int offset) {
    final isSelected = controller.selectedWeekOffset.value == offset;
    final bgColor = isSelected ? AppColors.primary700 : AppColors.surface;
    final textColor = isSelected ? AppColors.surface : AppColors.text;
    final borderColor = isSelected ? AppColors.primary700 : AppColors.border;

    return Expanded(
      child: InkWell(
        onTap: () => controller.selectWeekOffset(offset),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Center(
            child: IBText(label, context: context)
                .label
                .color(textColor)
                .build(),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekdayTabs(int selectedIndex) {
    final weekDays = controller.currentWeekDays;

    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ScheduleController.weekdayTabLabels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          final label = ScheduleController.weekdayTabLabels[index];
          final date = weekDays[index];
          final dayStr = date.day.toString().padLeft(2, '0');
          
          final textColor =
              isSelected ? AppColors.surface : AppColors.textMuted;
          final dateColor =
              isSelected ? AppColors.surface.withValues(alpha: 0.8) : AppColors.textMuted.withValues(alpha: 0.8);

          return InkWell(
            onTap: () => controller.selectWeekdayIndex(index),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary700 : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary700 : AppColors.border,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IBText(label, context: context)
                      .label
                      .color(textColor)
                      .build(),
                  const SizedBox(height: 2),
                  IBText(dayStr, context: context)
                      .caption
                      .color(dateColor)
                      .build(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoutineList(List<RoutineSection> sections) {
    if (!controller.hasRoutines) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in sections)
          _buildPeriodSection(section.title, section.items),
      ],
    );
  }

  Widget _buildPeriodSection(String title, List<RoutineOutput> routines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        IBText(title, context: context).subtitulo.build(),
        const SizedBox(height: 12),
        ...routines.map((routine) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildRoutineCard(routine),
            )),
      ],
    );
  }

  Widget _buildRoutineCard(RoutineOutput routine) {
    final cardColor = controller.routineTagColor(routine);
    final recurrenceLabel = routine.recurrenceTypeLabel;
    final secondaryLabel =
        '$recurrenceLabel • ${routine.weekdaysLabel}'.trim();

    return Dismissible(
      key: Key(routine.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger600,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const IBIcon(
          IBIcon.deleteOutlineRounded,
          color: AppColors.surface,
        ),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(routine);
      },
      onDismissed: (_) async {
        await controller.deleteRoutine(routine.id);
      },
      child: GestureDetector(
        onTap: () => _openEditRoutine(routine),
        child: IBItemCard(
          title: routine.title,
          secondary: secondaryLabel,
          typeLabel: routine.flagName ?? 'Rotina',
          typeColor: cardColor,
          typeIcon: IBIcon.repeatRounded,
          timeLabel: routine.timeLabel,
          timeIcon: IBIcon.alarmOutlined,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const IBCard(
      child: IBEmptyState(
        title: 'Nenhuma rotina para este dia',
        subtitle:
            'Adicione rotinas pelo botão + ou diga algo como "academia toda terça às 7h".',
        icon: IBHugeIcon.calendar,
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(RoutineOutput routine) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: IBText('Excluir rotina?', context: context).subtitulo.build(),
        content: IBText(
          'Tem certeza que deseja excluir "${routine.title}"?',
          context: context,
        ).body.build(),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: IBText('Cancelar', context: context).label.build(),
          ),
          TextButton(
            onPressed: () async {
              await controller.deleteRoutine(routine.id);
              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
            child: IBText('Excluir', context: context)
                .label
                .color(AppColors.danger600)
                .build(),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateRoutine() async {
    if (!mounted) return;

    controller.resetCreateForm();
    await IBBottomSheet.show<void>(
      smallBottomSheet: false,
      context: context,
      child: CreateRoutineBottomSheet(
        controller: controller,
      ),
    );
  }

  Future<void> _openEditRoutine(RoutineOutput routine) async {
    if (!mounted) return;

    controller.startEditRoutine(routine);
    await IBBottomSheet.show<void>(
      smallBottomSheet: false,
      context: context,
      child: CreateRoutineBottomSheet(
        controller: controller,
      ),
    );
  }
}
