import 'dart:async';

import 'package:flutter/material.dart';

import 'package:organiq/presentation/screens/home_module/components/timeline_item.dart';
import 'package:organiq/shared/components/oq_lib/index.dart';
import 'package:organiq/shared/theme/app_colors.dart';

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
    final nextItems = _dedupe(widget.nextItems);
    final nextKeys = nextItems.map((item) => item.stableKey).toSet();
    final pastItems = _dedupe(
      widget.pastItems.where((item) => !nextKeys.contains(item.stableKey)),
    );
    final allItems = <TimelineItem>[...nextItems, ...pastItems];

    if (allItems.isEmpty) {
      return const SizedBox.shrink();
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                OQText('A seguir', context: context).subtitulo.build(),
                const Spacer(),
                const OQIcon(
                  OQIcon.chevronRight,
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
                final isPast = index >= nextItems.length;
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
                        : OQNextActionCard(
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

  List<TimelineItem> _dedupe(Iterable<TimelineItem> items) {
    final seen = <String>{};
    final out = <TimelineItem>[];
    for (final item in items) {
      if (seen.add(item.stableKey)) {
        out.add(item);
      }
    }
    return out;
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

  OQNextActionItem _toIBItem(TimelineItem item) {
    return OQNextActionItem(
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

  OQNextActionType _mapType(TimelineItemType type) {
    switch (type) {
      case TimelineItemType.event:
        return OQNextActionType.event;
      case TimelineItemType.reminder:
        return OQNextActionType.reminder;
      case TimelineItemType.routine:
        return OQNextActionType.routine;
      case TimelineItemType.task:
        return OQNextActionType.task;
    }
  }
}
