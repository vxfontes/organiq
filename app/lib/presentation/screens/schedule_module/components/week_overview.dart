import 'package:flutter/material.dart';
import 'package:inbota/modules/routines/data/models/routine_output.dart';
import 'package:inbota/presentation/screens/schedule_module/components/routine_week_selector.dart';
import 'package:inbota/presentation/screens/schedule_module/controller/schedule_controller.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class WeekOverview extends StatelessWidget {
  const WeekOverview({
    super.key,
    required this.controller,
  });

  final ScheduleController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller.routinesByWeekdayInWeek,
      builder: (context, _) {
        final routinesMap = controller.routinesByWeekdayInWeek.value;
        final hasAnyRoutine = routinesMap.values.any((list) => list.isNotEmpty);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             RoutineWeekSelector(controller: controller),
            const SizedBox(height: 20),
            if (!hasAnyRoutine)
              const IBCard(
                child: IBEmptyState(
                  title: 'Nenhuma rotina para esta semana',
                  subtitle: 'Alterne a semana ou crie novas rotinas recorrentes.',
                  icon: IBHugeIcon.calendar,
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(7, (index) {
                        final apiWeekday = (index + 1) % 7;
                        final dayLabel = ScheduleController.weekdayTabLabels[index];
                        final dayRoutines = routinesMap[apiWeekday] ?? [];

                        return Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSoft,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Center(
                                  child: IBText(dayLabel, context: context).label.weight(FontWeight.w700).build(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (dayRoutines.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 20),
                                    child: IBText('-', context: context).muted.build(),
                                  ),
                                )
                              else
                                ...dayRoutines.map((r) => _buildMiniRoutineCard(context, r)),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMiniRoutineCard(BuildContext context, RoutineOutput routine) {
    final color = controller.routineTagColor(routine);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: IBText(routine.startTime, context: context).caption.color(AppColors.primary700).weight(FontWeight.w700).build(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          IBText(routine.title, context: context).label.maxLines(2).build(),
        ],
      ),
    );
  }
}
