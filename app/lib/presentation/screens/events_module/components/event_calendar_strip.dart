import 'package:flutter/material.dart';
import 'package:organiq/shared/components/oq_lib/index.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class EventCalendarStrip extends StatefulWidget {
  const EventCalendarStrip({
    super.key,
    required this.days,
    required this.selectedDate,
    required this.months,
    required this.weekdays,
    required this.onSelectDate,
  });

  final List<DateTime> days;
  final DateTime selectedDate;
  final List<String> months;
  final List<String> weekdays;
  final ValueChanged<DateTime> onSelectDate;

  @override
  State<EventCalendarStrip> createState() => _EventCalendarStripState();
}

class _EventCalendarStripState extends State<EventCalendarStrip> {
  static const double _itemWidth = 88;
  static const double _itemSpacing = 5;
  static const double _previousPeekFraction = 0.10;

  late final ScrollController _scrollController;
  bool _didInitialPosition = false;
  final DateTime _today = _startOfDay(DateTime.now());

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scheduleInitialPosition();
  }

  @override
  void didUpdateWidget(covariant EventCalendarStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_didInitialPosition && widget.days.isNotEmpty) {
      _scheduleInitialPosition();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleInitialPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didInitialPosition || widget.days.isEmpty) return;
      if (!_scrollController.hasClients) return;

      var targetIndex = _indexOfDay(widget.days, _today);
      if (targetIndex == -1) {
        targetIndex = _indexOfDay(
          widget.days,
          _startOfDay(widget.selectedDate),
        );
      }
      if (targetIndex == -1) return;

      final baseOffset = targetIndex * (_itemWidth + _itemSpacing);
      const peekOffset = (_itemWidth * _previousPeekFraction) + _itemSpacing;
      final targetOffset = targetIndex > 0 ? (baseOffset - peekOffset) : 0.0;
      final clampedOffset = targetOffset.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );

      _scrollController.jumpTo(clampedOffset);
      _didInitialPosition = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.days.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 100,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: widget.days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 5),
        itemBuilder: (context, index) {
          final day = widget.days[index];
          final isSelected =
              day.year == widget.selectedDate.year &&
              day.month == widget.selectedDate.month &&
              day.day == widget.selectedDate.day;

          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => widget.onSelectDate(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 88,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary700 : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary700 : AppColors.border,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OQText(widget.months[day.month - 1], context: context).caption
                      .color(
                        isSelected ? AppColors.surface : AppColors.textMuted,
                      )
                      .build(),
                  const SizedBox(height: 2),
                  OQText('${day.day}', context: context).titulo
                      .color(isSelected ? AppColors.surface : AppColors.text)
                      .build(),
                  const SizedBox(height: 2),
                  OQText(_weekdayLabel(day), context: context).caption
                      .color(
                        isSelected ? AppColors.surface : AppColors.textMuted,
                      )
                      .build(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _weekdayLabel(DateTime date) {
    final adjusted = date.weekday == 7 ? 6 : date.weekday - 1;
    return widget.weekdays[adjusted];
  }

  int _indexOfDay(List<DateTime> days, DateTime target) {
    for (var i = 0; i < days.length; i++) {
      if (_isSameDay(days[i], target)) return i;
    }
    return -1;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
