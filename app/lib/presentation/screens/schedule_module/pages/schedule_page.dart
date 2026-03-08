import 'package:flutter/material.dart';

import 'package:inbota/modules/routines/data/models/routine_output.dart';
import 'package:inbota/modules/routines/data/models/routine_section.dart';
import 'package:inbota/presentation/routes/app_navigation.dart';
import 'package:inbota/presentation/screens/schedule_module/components/create_routine_bottom_sheet.dart';
import 'package:inbota/presentation/screens/schedule_module/components/routine_detail_bottom_sheet.dart';
import 'package:inbota/presentation/screens/schedule_module/components/routine_week_selector.dart';
import 'package:inbota/presentation/screens/schedule_module/components/week_overview.dart';
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
    controller.error.addListener(_onErrorChanged);
  }

  @override
  void dispose() {
    controller.error.removeListener(_onErrorChanged);
    super.dispose();
  }

  void _onErrorChanged() {
    final error = controller.error.value;
    if (error != null && error.isNotEmpty && mounted) {
      IBSnackBar.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        controller.loading,
        controller.viewMode,
        controller.routinesByPeriod,
        controller.selectedWeekday,
        controller.selectedWeekOffset,
      ]),
      builder: (context, _) {
        final mode = controller.viewMode.value;
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
                  const SizedBox(height: 16),
                  if (mode == ScheduleViewMode.daily) ...[
                    RoutineWeekSelector(controller: controller),
                    const SizedBox(height: 20),
                    _buildWeekdayTabs(selectedWeekdayIndex),
                    const SizedBox(height: 20),
                    _buildRoutineList(routineSections),
                  ] else ...[
                    WeekOverview(controller: controller),
                  ],
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
        ValueListenableBuilder<ScheduleViewMode>(
          valueListenable: controller.viewMode,
          builder: (context, mode, _) {
            return IconButton(
              tooltip: mode == ScheduleViewMode.daily ? 'Ver semana' : 'Ver dia',
              onPressed: controller.toggleViewMode,
              icon: IBIcon(
                mode == ScheduleViewMode.daily
                    ? IBIcon.calendarMonthRounded
                    : IBIcon.calendarTodayRounded,
                color: AppColors.primary700,
                size: 20,
              ),
            );
          },
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

  Widget _buildWeekdayTabs(int selectedIndex) {
    final weekDays = controller.currentWeekDays;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

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
          
          final isToday = date.year == today.year && 
                         date.month == today.month && 
                         date.day == today.day;

          final textColor = isSelected ? AppColors.surface : AppColors.text;
          final dateColor = isSelected ? AppColors.surface.withValues(alpha: 0.8) : AppColors.textMuted;

          return InkWell(
            onTap: () => controller.selectWeekdayIndex(index),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 58,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary700 : AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected 
                      ? AppColors.primary700 
                      : (isToday ? AppColors.primary600.withValues(alpha: 0.5) : AppColors.border),
                  width: isToday && !isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IBText(label, context: context)
                      .label
                      .color(textColor)
                      .weight(isToday ? FontWeight.w800 : FontWeight.w400)
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
        const SizedBox(height: 20),
        IBText(title, context: context).subtitulo.build(),
        const SizedBox(height: 12),
        ...routines.map((routine) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
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
    final conflicts = controller.getConflicts(routine);

    final typeLabel = routine.subflagName != null 
        ? '${routine.flagName} > ${routine.subflagName}' 
        : (routine.flagName ?? 'Rotina');

    return Dismissible(
      key: Key(routine.id),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppColors.warning500,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const IBIcon(
              IBIcon.skipNextRounded,
              color: AppColors.surface,
            ),
            const SizedBox(width: 8),
            IBText('Pular', context: null).label.color(AppColors.surface).build(),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger600,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IBText('Excluir', context: null).label.color(AppColors.surface).build(),
            const SizedBox(width: 8),
            const IBIcon(
              IBIcon.deleteOutlineRounded,
              color: AppColors.surface,
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          final success = await controller.skipToday(routine);
          if (success) {
            IBSnackBar.success(context, 'Rotina "${routine.title}" pulada hoje.');
          }
          return false;
        }
        return await _showDeleteConfirmation(routine);
      },
      onDismissed: (direction) async {
        if (direction == DismissDirection.endToStart) {
          await controller.deleteRoutine(routine.id);
        }
      },
      child: GestureDetector(
        onTap: () => _openRoutineDetails(routine),
        onLongPress: () => _openEditRoutine(routine),
        child: IBItemCard(
          title: routine.title,
          secondary: secondaryLabel,
          done: routine.isCompletedToday,
          doneLabel: 'Concluída',
          onToggle: (val) => controller.toggleRoutine(routine, val),
          typeLabel: typeLabel,
          typeColor: cardColor,
          typeIcon: IBIcon.repeatRounded,
          timeLabel: routine.timeLabel,
          timeIcon: IBIcon.alarmOutlined,
          footer: conflicts.isNotEmpty
              ? Row(
                  children: [
                    const IBIcon(
                      IBIcon.errorOutlineRounded,
                      color: AppColors.warning500,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    IBText(
                      'Conflito com: ${conflicts.first.title}',
                      context: context,
                    ).caption.color(AppColors.warning600).build(),
                  ],
                )
              : null,
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
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: IBText('Excluir rotina?', context: context).subtitulo.build(),
        content: IBText(
          'Tem certeza que deseja excluir "${routine.title}"?',
          context: context,
        ).body.build(),
        actions: [
          IBButton(
            label: 'Cancelar',
            variant: IBButtonVariant.ghost,
            onPressed: () => AppNavigation.pop(false, context),
          ),
          IBButton(
            label: 'Excluir',
            variant: IBButtonVariant.primary,
            onPressed: () async {
              await controller.deleteRoutine(routine.id);
              if (context.mounted) {
                AppNavigation.pop(true, context);
              }
            },
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

  Future<void> _openRoutineDetails(RoutineOutput routine) async {
    if (!mounted) return;

    await IBBottomSheet.show<void>(
      context: context,
      isFitWithContent: true,
      child: RoutineDetailBottomSheet(
        routine: routine,
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
