import 'package:flutter/material.dart';

import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/theme/app_colors.dart';
import 'package:inbota/shared/utils/text_utils.dart';

class HomeBentoRow extends StatelessWidget {
  static const double _sideCardHeight = 160;

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
    required this.eventsTodayCount,
    required this.remindersTodayCount,
    required this.onShoppingTap,
    required this.onAgendaTap,
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
  final int eventsTodayCount;
  final int remindersTodayCount;
  final VoidCallback onShoppingTap;
  final VoidCallback onAgendaTap;

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
                    flex: 6,
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
                      child: _buildAgendaTodayCard(context),
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
                    child: _buildAgendaTodayCard(context),
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

  Widget _buildAgendaTodayCard(BuildContext context) {
    final commitments = eventsTodayCount + remindersTodayCount;
    final summary = commitments == 0
        ? 'Dia livre'
        : TextUtils.countLabel(commitments, 'compromisso', 'compromissos');

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onAgendaTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IBIcon(
                IBIcon.calendar,
                size: 18,
                color: AppColors.success600,
              ),
              const SizedBox(height: 8),
              IBText('Agenda hoje', context: context).subtitulo.build(),
              const SizedBox(height: 4),
              IBText(summary, context: context).muted.maxLines(2).build(),
              const SizedBox(height: 10),
              IBText(
                '$eventsTodayCount evento(s) • $remindersTodayCount lembrete(s)',
                context: context,
              ).caption.build(),
            ],
          ),
        ),
      ),
    );
  }
}
