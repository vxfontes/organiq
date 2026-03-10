import 'package:flutter/material.dart';

import 'package:inbota/shared/components/ib_lib/index.dart';

class HomeBentoRow extends StatelessWidget {
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
    required this.onShoppingTap,
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
  final VoidCallback onShoppingTap;

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
              _buildShoppingBanner(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: _buildProgressCard()),
            const SizedBox(width: 12),
            Expanded(flex: 5, child: _buildShoppingBanner()),
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
}
