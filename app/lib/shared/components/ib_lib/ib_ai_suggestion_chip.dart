import 'package:flutter/material.dart';
import 'package:inbota/shared/components/ib_lib/ib_text.dart';
import 'package:inbota/shared/theme/app_colors.dart';

enum IBAISuggestionType {
  event,
  reminder,
  shopping,
  task,
}

class IBAISuggestionChip extends StatefulWidget {
  const IBAISuggestionChip({
    super.key,
    required this.label,
    required this.onTap,
    this.type = IBAISuggestionType.task,
    this.icon,
    this.isSelected = false,
  });

  final String label;
  final VoidCallback onTap;
  final IBAISuggestionType type;
  final IconData? icon;
  final bool isSelected;

  @override
  State<IBAISuggestionChip> createState() => _IBAISuggestionChipState();
}

class _IBAISuggestionChipState extends State<IBAISuggestionChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    if (widget.isSelected) {
      return _typeColor.withAlpha((0.2 * 255).round());
    }
    return AppColors.surface2;
  }

  Color get _typeColor {
    switch (widget.type) {
      case IBAISuggestionType.event:
        return AppColors.success600;
      case IBAISuggestionType.reminder:
        return AppColors.ai600;
      case IBAISuggestionType.shopping:
        return AppColors.warning500;
      case IBAISuggestionType.task:
        return AppColors.primary600;
    }
  }

  IconData get _defaultIcon {
    switch (widget.type) {
      case IBAISuggestionType.event:
        return Icons.event_rounded;
      case IBAISuggestionType.reminder:
        return Icons.notifications_rounded;
      case IBAISuggestionType.shopping:
        return Icons.shopping_cart_rounded;
      case IBAISuggestionType.task:
        return Icons.check_circle_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected ? _typeColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon ?? _defaultIcon,
                size: 16,
                color: _typeColor,
              ),
              const SizedBox(width: 6),
              IBText(
                widget.label,
                context: context,
              ).caption.color(_typeColor).build(),
            ],
          ),
        ),
      ),
    );
  }
}

class IBAISuggestionChipGroup extends StatelessWidget {
  const IBAISuggestionChipGroup({
    super.key,
    required this.suggestions,
    this.onSuggestionTap,
  });

  final List<IBAISuggestionData> suggestions;
  final ValueChanged<IBAISuggestionData>? onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions.map((suggestion) {
        return IBAISuggestionChip(
          label: suggestion.label,
          type: suggestion.type,
          icon: suggestion.icon,
          onTap: () => onSuggestionTap?.call(suggestion),
        );
      }).toList(),
    );
  }
}

class IBAISuggestionData {
  const IBAISuggestionData({
    required this.label,
    required this.type,
    this.icon,
  });

  final String label;
  final IBAISuggestionType type;
  final IconData? icon;
}
