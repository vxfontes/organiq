import 'package:flutter/material.dart';

import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class HomeBentoRow extends StatelessWidget {
  static const double _sideCardHeight = 170;

  const HomeBentoRow({
    super.key,
    required this.progressPercent,
    required this.routinesDone,
    required this.routinesTotal,
    required this.tasksDone,
    required this.tasksTotal,
    required this.remindersDone,
    required this.remindersTotal,
    required this.shoppingListCount,
    required this.shoppingItemCount,
    required this.insightTitle,
    required this.insightSummary,
    required this.insightFooter,
    required this.insightIsFocus,
    required this.onShoppingTap,
    required this.onInsightsTap,
  });

  final double progressPercent;
  final int routinesDone;
  final int routinesTotal;
  final int tasksDone;
  final int tasksTotal;
  final int remindersDone;
  final int remindersTotal;
  final int shoppingListCount;
  final int shoppingItemCount;
  final String insightTitle;
  final String insightSummary;
  final String insightFooter;
  final bool insightIsFocus;
  final VoidCallback onShoppingTap;
  final VoidCallback onInsightsTap;

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
      remindersDone: remindersDone,
      remindersTotal: remindersTotal,
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
    final highlightColor = insightIsFocus
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
                insightTitle,
                context: context,
              ).subtitulo.weight(FontWeight.w700).build(),
              const SizedBox(height: 4),
              IBText(
                insightSummary,
                context: context,
              ).muted.maxLines(3).build(),
              const SizedBox(height: 10),
              IBText(
                insightFooter,
                context: context,
              ).caption.color(highlightColor).maxLines(2).build(),
            ],
          ),
        ),
      ),
    );
  }
}
