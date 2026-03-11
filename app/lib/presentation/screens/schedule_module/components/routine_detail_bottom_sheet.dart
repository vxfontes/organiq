import 'package:flutter/material.dart';
import 'package:inbota/modules/routines/data/models/routine_activity_day_output.dart';
import 'package:inbota/modules/routines/data/models/routine_output.dart';
import 'package:inbota/modules/routines/data/models/routine_streak_output.dart';
import 'package:inbota/presentation/routes/app_navigation.dart';
import 'package:inbota/presentation/screens/schedule_module/components/create_routine_bottom_sheet.dart';
import 'package:inbota/presentation/screens/schedule_module/controller/schedule_controller.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class RoutineDetailBottomSheet extends StatefulWidget {
  const RoutineDetailBottomSheet({
    super.key,
    required this.routine,
    required this.controller,
  });

  final RoutineOutput routine;
  final ScheduleController controller;

  @override
  State<RoutineDetailBottomSheet> createState() => _RoutineDetailBottomSheetState();
}

class _RoutineDetailBottomSheetState extends State<RoutineDetailBottomSheet> {
  final ScrollController _activityScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.loadRoutineDetails(widget.routine.id);
    
    // scroll começa no final (dia de hoje)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_activityScrollController.hasClients) {
        _activityScrollController.jumpTo(_activityScrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _activityScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.controller.detailsLoading,
        widget.controller.currentRoutineHistory,
        widget.controller.currentRoutineStreak,
      ]),
      builder: (context, _) {
        final isLoading = widget.controller.detailsLoading.value;
        final history = widget.controller.currentRoutineHistory.value;
        final streak = widget.controller.currentRoutineStreak.value;

        return SingleChildScrollView(
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
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildInfoGrid(context),
              const SizedBox(height: 16),
              _buildProgressSection(context, history, streak, isLoading),
              const SizedBox(height: 24),
              _buildActions(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final color = widget.controller.routineTagColor(widget.routine);
    final hasFlag = widget.routine.flagName != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IBText(widget.routine.title, context: context).titulo.build(),
                  if (widget.routine.description != null && widget.routine.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    IBText(widget.routine.description!, context: context).body.color(AppColors.textMuted).build(),
                  ],
                ],
              ),
            ),
            if (hasFlag)
              IBChip(
                label: widget.routine.subflagName ?? widget.routine.flagName!,
                color: color,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoGrid(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(child: _buildCompactInfo(context, 'Horário', widget.routine.timeLabel, IBIcon.alarmOutlined)),
            const VerticalDivider(color: AppColors.border, indent: 4, endIndent: 4),
            Expanded(child: _buildCompactInfo(context, 'Dias', widget.routine.weekdaysLabel, IBIcon.calendar)),
            const VerticalDivider(color: AppColors.border, indent: 4, endIndent: 4),
            Expanded(child: _buildCompactInfo(context, 'Frequência', widget.routine.recurrenceTypeLabel, IBIcon.repeatRounded)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInfo(BuildContext context, String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IBIcon(icon, size: 16, color: AppColors.primary600),
        const SizedBox(height: 4),
        IBText(label, context: context).caption.color(AppColors.textMuted).build(),
        const SizedBox(height: 2),
        IBText(value, context: context).label.weight(FontWeight.w600).maxLines(1).build(),
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context, List<dynamic> history, RoutineStreakOutput? streak, bool isLoading) {
    if (isLoading) return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));

    final hasStreak = streak != null && streak.currentStreak > 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasStreak ? AppColors.ai500.withValues(alpha: 0.05) : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hasStreak ? AppColors.ai500.withValues(alpha: 0.2) : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IBText('Progresso', context: context).label.weight(FontWeight.w700).build(),
              const Spacer(),
              if (hasStreak) ...[
                const IBIcon(IBIcon.fireRounded, size: 16, color: AppColors.ai500),
                const SizedBox(width: 4),
                IBText(streak.streakText, context: context).label.weight(FontWeight.w700).color(AppColors.ai600).build(),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (streak != null)
            _buildActivityStrip(context, streak.activity),
        ],
      ),
    );
  }

  Widget _buildActivityStrip(BuildContext context, List<RoutineActivityDayOutput> activity) {
    // scroll vá para o final
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_activityScrollController.hasClients) {
        _activityScrollController.animateTo(
          _activityScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return SingleChildScrollView(
      controller: _activityScrollController,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: activity.map<Widget>((day) {
          final isCompleted = day.isCompleted;
          final isScheduled = day.isScheduled;
          final isToday = day.isToday;
          final isSkipped = day.isSkipped;

          Color color = AppColors.border.withValues(alpha: 0.3);
          if (isCompleted) {
            color = AppColors.primary600;
          } else if (isSkipped) {
            color = AppColors.warning500.withValues(alpha: 0.4);
          } else if (isScheduled && !isToday) {
            color = AppColors.danger600.withValues(alpha: 0.2);
          } else if (isScheduled) {
            color = AppColors.primary600.withValues(alpha: 0.1);
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isToday ? Border.all(color: AppColors.primary600, width: 2) : null,
                  ),
                  child: isCompleted 
                    ? const IBIcon(IBIcon.checkRounded, size: 16, color: Colors.white)
                    : (isSkipped ? const IBIcon(IBIcon.forwardRounded, size: 16, color: Colors.white) : null),
                ),
                const SizedBox(height: 6),
                IBText(day.weekdayLabel, context: context).caption.color(isToday ? AppColors.text : AppColors.textMuted).weight(isToday ? FontWeight.w800 : FontWeight.w400).build(),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: IBButton(
            label: 'Editar',
            variant: IBButtonVariant.secondary,
            onPressed: () {
              AppNavigation.pop(null, context);
              widget.controller.startEditRoutine(widget.routine);
              _openEditForm();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: IBButton(
            label: widget.routine.isActive ? 'Desativar' : 'Ativar',
            variant: IBButtonVariant.ghost,
            onPressed: () {
              widget.controller.toggleRoutineActive(widget.routine, !widget.routine.isActive);
              AppNavigation.pop(null, context);
            },
          ),
        ),
      ],
    );
  }

  void _openEditForm() {
    IBBottomSheet.show<void>(
      context: context,
      smallBottomSheet: false,
      child: CreateRoutineBottomSheet(controller: widget.controller),
    );
  }
}
