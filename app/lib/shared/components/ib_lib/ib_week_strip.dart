import 'package:flutter/material.dart';

import 'package:inbota/shared/components/ib_lib/ib_text.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class IBWeekStrip extends StatefulWidget {
  const IBWeekStrip({
    super.key,
    required this.selectedDate,
    required this.densityMap,
    required this.onDayTap,
  });

  final DateTime selectedDate;
  final Map<DateTime, int> densityMap;
  final ValueChanged<DateTime> onDayTap;

  @override
  State<IBWeekStrip> createState() => _IBWeekStripState();
}

class _IBWeekStripState extends State<IBWeekStrip> {
  static const List<String> _weekdayLabels = [
    'SEG',
    'TER',
    'QUA',
    'QUI',
    'SEX',
    'SAB',
    'DOM',
  ];

  static const double _itemWidth = 52;
  static const double _itemSpacing = 8;

  late final ScrollController _scrollController;
  bool _didInitialCenter = false;
  DateTime? _lastWeekStart;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _lastWeekStart = _startOfWeek(widget.selectedDate);
    _scheduleInitialCenter();
  }

  @override
  void didUpdateWidget(covariant IBWeekStrip oldWidget) {
    super.didUpdateWidget(oldWidget);

    final nextWeekStart = _startOfWeek(widget.selectedDate);
    if (_lastWeekStart == null || !_isSameDay(nextWeekStart, _lastWeekStart!)) {
      _didInitialCenter = false;
      _lastWeekStart = nextWeekStart;
    }

    if (!_didInitialCenter) {
      _scheduleInitialCenter();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysOfWeek(widget.selectedDate);

    return SizedBox(
      height: 88,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = _isSameDay(day, widget.selectedDate);
          final isPast = _startOfDay(day).isBefore(_startOfDay(DateTime.now()));
          final density = _densityFor(day);

          return Opacity(
            opacity: isPast && !isSelected ? 0.55 : 1,
            child: Padding(
              padding: EdgeInsets.only(
                right: index == days.length - 1 ? 0 : _itemSpacing,
              ),
              child: InkWell(
                onTap: () => widget.onDayTap(day),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: _itemWidth,
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 4,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IBText(_weekdayLabels[day.weekday - 1], context: context)
                          .caption
                          .weight(FontWeight.w600)
                          .color(
                            isSelected
                                ? AppColors.primary700
                                : AppColors.textMuted,
                          )
                          .build(),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppColors.primary700
                              : AppColors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary700
                                : AppColors.border,
                          ),
                        ),
                        child: IBText('${day.day}', context: context).label
                            .weight(FontWeight.w700)
                            .color(
                              isSelected ? AppColors.surface : AppColors.text,
                            )
                            .build(),
                      ),
                      const SizedBox(height: 6),
                      _DensityDots(
                        count: _dotCount(density),
                        selected: isSelected,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _scheduleInitialCenter() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didInitialCenter) return;
      if (!_scrollController.hasClients) return;

      final days = _daysOfWeek(widget.selectedDate);
      if (days.isEmpty) return;

      final target = _startOfDay(DateTime.now());
      var targetIndex = _indexOfDay(days, target);
      if (targetIndex == -1) {
        targetIndex = _indexOfDay(days, _startOfDay(widget.selectedDate));
      }
      if (targetIndex == -1) return;

      final viewport = _scrollController.position.viewportDimension;
      const totalItemWidth = _itemWidth + _itemSpacing;
      final centered =
          (targetIndex * totalItemWidth) - ((viewport - _itemWidth) / 2);
      final clamped = centered.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );

      _scrollController.jumpTo(clamped);
      _didInitialCenter = true;
    });
  }

  List<DateTime> _daysOfWeek(DateTime anchor) {
    final start = _startOfWeek(anchor);
    return List<DateTime>.generate(
      7,
      (index) => start.add(Duration(days: index)),
      growable: false,
    );
  }

  DateTime _startOfWeek(DateTime value) {
    final day = _startOfDay(value);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  int _densityFor(DateTime day) {
    for (final entry in widget.densityMap.entries) {
      if (_isSameDay(entry.key, day)) return entry.value;
    }
    return 0;
  }

  int _dotCount(int density) {
    if (density <= 0) return 0;
    if (density <= 2) return 1;
    if (density <= 5) return 2;
    return 3;
  }

  int _indexOfDay(List<DateTime> days, DateTime target) {
    for (var i = 0; i < days.length; i++) {
      if (_isSameDay(days[i], target)) return i;
    }
    return -1;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

class _DensityDots extends StatelessWidget {
  const _DensityDots({required this.count, required this.selected});

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox(height: 6);

    final color = selected
        ? AppColors.primary700.withValues(alpha: 0.9)
        : AppColors.primary600.withValues(alpha: 0.7);

    return SizedBox(
      height: 6,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List<Widget>.generate(count, (index) {
          return Container(
            width: 4,
            height: 4,
            margin: EdgeInsets.only(right: index == count - 1 ? 0 : 3),
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          );
        }),
      ),
    );
  }
}
