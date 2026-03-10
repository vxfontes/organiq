import 'package:flutter/material.dart';

import 'package:inbota/presentation/screens/home_module/components/timeline_item.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/theme/app_colors.dart';
import 'package:inbota/shared/utils/home_insights_utils.dart';

class HomeBentoRow extends StatelessWidget {
  static const double _sideCardHeight = 170;

  const HomeBentoRow({
    super.key,
    required this.progressPercent,
    required this.routinesDone,
    required this.routinesTotal,
    required this.tasksDone,
    required this.tasksTotal,
    required this.shoppingListCount,
    required this.shoppingItemCount,
    required this.eventsTodayCount,
    required this.remindersTodayCount,
    required this.todayTimeline,
    required this.onShoppingTap,
    required this.onInsightsTap,
    this.debugInsightLogs = false,
  });

  final double progressPercent;
  final int routinesDone;
  final int routinesTotal;
  final int tasksDone;
  final int tasksTotal;
  final int shoppingListCount;
  final int shoppingItemCount;
  final int eventsTodayCount;
  final int remindersTodayCount;
  final List<TimelineItem> todayTimeline;
  final VoidCallback onShoppingTap;
  final VoidCallback onInsightsTap;
  final bool debugInsightLogs;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useStackedLayout = constraints.maxWidth < 460;

        if (useStackedLayout) {
          return Column(
            children: [
              _buildProgressCard(),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: SizedBox(
                      height: _sideCardHeight,
                      child: _buildShoppingBanner(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: SizedBox(
                      height: _sideCardHeight,
                      child: _buildInsightsCard(context),
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: _buildProgressCard()),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  SizedBox(
                    height: _sideCardHeight,
                    child: _buildShoppingBanner(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: _sideCardHeight,
                    child: _buildInsightsCard(context),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgressCard() {
    return IBDayProgressCard(
      progressPercent: progressPercent,
      routinesDone: routinesDone,
      routinesTotal: routinesTotal,
      tasksDone: tasksDone,
      tasksTotal: tasksTotal,
    );
  }

  Widget _buildShoppingBanner() {
    return IBShoppingBanner(
      listCount: shoppingListCount,
      itemCount: shoppingItemCount,
      onTap: onShoppingTap,
    );
  }

  Widget _buildInsightsCard(BuildContext context) {
    final commitments =
        eventsTodayCount + remindersTodayCount + tasksTotal + routinesTotal;
    final slots = todayTimeline
        .map(
          (item) => DayScheduleSlot(
            start: item.scheduledTime,
            end: item.endScheduledTime,
          ),
        )
        .toList(growable: false);
    final untimedCount = (commitments - slots.length).clamp(0, 9999).toInt();

    if (debugInsightLogs) {
      debugPrint(
        '[Insights] commitments=$commitments events=$eventsTodayCount reminders=$remindersTodayCount tasks=$tasksTotal routines=$routinesTotal slots=${slots.length}',
      );
      for (final item in todayTimeline) {
        debugPrint(
          '[Insights] item type=${item.type.name} completed=${item.isCompleted} ${item.scheduledTime} -> ${item.endScheduledTime}',
        );
      }
    }

    final insight = HomeInsightsUtils.buildDailyInsight(
      slots: slots,
      commitmentsCount: commitments,
      untimedCount: untimedCount,
      debugLogs: debugInsightLogs,
    );
    final highlightColor = insight.isFocus
        ? AppColors.primary600
        : AppColors.success600;

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onInsightsTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IBIcon(
                IBIcon.autoAwesomeRounded,
                size: 18,
                color: highlightColor,
              ),
              const SizedBox(height: 8),
              IBText(
                insight.title,
                context: context,
              ).subtitulo.weight(FontWeight.w700).build(),
              const SizedBox(height: 4),
              IBText(
                insight.summary,
                context: context,
              ).muted.maxLines(3).build(),
              const SizedBox(height: 10),
              IBText(
                insight.footer,
                context: context,
              ).caption.color(highlightColor).maxLines(2).build(),
            ],
          ),
        ),
      ),
    );
  }
}
