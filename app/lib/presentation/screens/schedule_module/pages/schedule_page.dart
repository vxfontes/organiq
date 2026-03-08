import 'package:flutter/material.dart';

import 'package:inbota/modules/routines/data/models/routine_output.dart';
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
        controller.todayTotal,
        controller.todayCompleted,
      ]),
      builder: (context, _) {
        final error = controller.error.value;
        final selectedWeekdayIndex = controller.selectedWeekdayIndex;
        final todayProgress = controller.todayProgress;
        final todayProgressLabel = controller.todayProgressLabel;
        final todayPercentageLabel = controller.todayPercentageLabel;
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
                  const SizedBox(height: 20),
                  if (controller.shouldShowProgress)
                    _buildProgressBar(
                      todayProgress,
                      todayProgressLabel,
                      todayPercentageLabel,
                    ),
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

  Widget _buildProgressBar(
    double progress,
    String progressLabel,
    String percentageLabel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IBText(progressLabel, context: context)
                .caption
                .build(),
            IBText(percentageLabel, context: context)
                .caption
                .color(AppColors.primary700)
                .build(),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? AppColors.success600 : AppColors.primary700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayTabs(int selectedIndex) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ScheduleController.weekdayTabLabels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => controller.selectWeekdayIndex(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary700 : AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.primary700 : AppColors.border,
                ),
              ),
              child: Center(
                child: Text(
                  ScheduleController.weekdayTabLabels[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textMuted,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  ),
                ),
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
    final isCompleted = controller.isCompletedToday(routine.id);
    final cardColor = controller.routineTagColor(routine);

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
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(routine);
      },
      child: IBCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _toggleComplete(routine),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted ? AppColors.success600 : cardColor,
                    width: 2,
                  ),
                  color: isCompleted ? AppColors.success600 : Colors.transparent,
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routine.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted
                          ? AppColors.textMuted
                          : AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        routine.recurrenceTypeLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      if (routine.flagName != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: cardColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            routine.flagName!,
                            style: TextStyle(
                              fontSize: 11,
                              color: cardColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                routine.timeLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cardColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          IBText(
            'Nenhuma rotina para este dia',
            context: context,
          ).subtitulo.build(),
          const SizedBox(height: 8),
          IBText(
            'Adicione rotinas pelo botão + ou diga algo como "academia toda terça às 7h"',
            context: context,
          ).muted.build(),
        ],
      ),
    );
  }

  Future<void> _toggleComplete(RoutineOutput routine) async {
    final isCompleted = controller.isCompletedToday(routine.id);
    if (isCompleted) {
      await controller.uncompleteRoutine(routine.id);
    } else {
      await controller.completeRoutine(routine.id);
    }
  }

  Future<bool?> _showDeleteConfirmation(RoutineOutput routine) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir rotina?'),
        content: Text('Tem certeza que deseja excluir "${routine.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await controller.deleteRoutine(routine.id);
              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
            child: Text(
              'Excluir',
              style: TextStyle(color: AppColors.danger600),
            ),
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
}
