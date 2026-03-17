import 'package:flutter/material.dart';
import 'package:organiq/presentation/screens/events_module/controller/events_controller.dart';
import 'package:organiq/shared/components/oq_lib/index.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class EventFilters extends StatelessWidget {
  const EventFilters({
    super.key,
    required this.selected,
    required this.labelBuilder,
    required this.onSelect,
  });

  final EventFeedFilter selected;
  final String Function(EventFeedFilter filter) labelBuilder;
  final ValueChanged<EventFeedFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    const filters = EventFeedFilter.values;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter == selected;

          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onSelect(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary700
                    : AppColors.primary100.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary700
                      : AppColors.primary200,
                ),
              ),
              child: Center(
                child: OQText(labelBuilder(filter), context: context).label
                    .color(
                      isSelected ? AppColors.surface : AppColors.primary700,
                    )
                    .build(),
              ),
            ),
          );
        },
      ),
    );
  }
}
