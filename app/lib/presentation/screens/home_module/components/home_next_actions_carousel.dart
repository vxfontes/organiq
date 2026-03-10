import 'dart:async';

import 'package:flutter/material.dart';

import 'package:inbota/presentation/screens/home_module/components/timeline_item.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class HomeNextActionsCarousel extends StatefulWidget {
  const HomeNextActionsCarousel({
    super.key,
    required this.pastItems,
    required this.nextItems,
    this.onComplete,
  });

  final List<TimelineItem> pastItems;
  final List<TimelineItem> nextItems;
  final ValueChanged<TimelineItem>? onComplete;

  @override
  State<HomeNextActionsCarousel> createState() =>
      _HomeNextActionsCarouselState();
}

class _HomeNextActionsCarouselState extends State<HomeNextActionsCarousel> {
  final Set<String> _completingIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final allItems = <TimelineItem>[...widget.nextItems, ...widget.pastItems];

    if (allItems.isEmpty) {
      return const SizedBox.shrink();
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                IBText('A seguir', context: context).subtitulo.build(),
                const Spacer(),
                const IBIcon(
                  IBIcon.chevronRight,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 122,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: allItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, index) {
                final item = allItems[index];
                final isPast = index >= widget.nextItems.length;
                final isCompleting = _completingIds.contains(item.stableKey);

                return AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: isCompleting
                        ? const SizedBox.shrink()
                        : IBNextActionCard(
                            key: ValueKey(item.stableKey),
                            item: _toIBItem(item),
                            isPast: isPast,
                            onComplete: widget.onComplete == null || isPast
                                ? null
                                : () => _handleComplete(item),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }
  }

  Future<void> _handleComplete(TimelineItem item) async {
    final stableKey = item.stableKey;
    if (_completingIds.contains(stableKey)) return;

    setState(() => _completingIds.add(stableKey));

    await Future<void>.delayed(const Duration(milliseconds: 220));
    widget.onComplete?.call(item);

    if (!mounted) return;
    setState(() => _completingIds.remove(stableKey));
  }

  IBNextActionItem _toIBItem(TimelineItem item) {
    return IBNextActionItem(
      id: item.id,
      title: item.title,
      subtitle: item.subtitle,
      type: _mapType(item.type),
      scheduledTime: item.scheduledTime,
      endScheduledTime: item.endScheduledTime,
      isCompleted: item.isCompleted,
      isOverdue: item.isOverdue,
    );
  }

  IBNextActionType _mapType(TimelineItemType type) {
    switch (type) {
      case TimelineItemType.event:
        return IBNextActionType.event;
      case TimelineItemType.reminder:
        return IBNextActionType.reminder;
      case TimelineItemType.routine:
        return IBNextActionType.routine;
      case TimelineItemType.task:
        return IBNextActionType.task;
    }
  }
}
