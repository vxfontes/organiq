import 'package:flutter/material.dart';

import 'package:hugeicons/hugeicons.dart';
import 'package:organiq/shared/components/oq_lib/oq_huge_icons.dart';
import 'package:organiq/shared/components/oq_lib/oq_icon.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class OQBottomNav extends StatelessWidget {
  const OQBottomNav({super.key, this.currentIndex = 2, this.onTap});

  final int currentIndex;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.text.withAlpha((0.08 * 255).round()),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: AppColors.surface.withAlpha((0.9 * 255).round()),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _NavIcon(
                      index: 0,
                      icon: OQHugeIcon.home,
                      isActive: currentIndex == 0,
                      onTap: onTap,
                    ),
                    _NavIcon(
                      index: 1,
                      icon: OQHugeIcon.schedule,
                      isActive: currentIndex == 1,
                      onTap: onTap,
                    ),
                    const SizedBox(width: 56),
                    _NavIcon(
                      index: 3,
                      icon: OQHugeIcon.shoppingBag,
                      isActive: currentIndex == 3,
                      onTap: onTap,
                    ),
                    _NavIcon(
                      index: 4,
                      icon: OQHugeIcon.calendar,
                      isActive: currentIndex == 4,
                      onTap: onTap,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 35,
            child: _CenterAction(isActive: currentIndex == 2, onTap: onTap),
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.index,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final int index;
  final OQHugeIcon icon;
  final bool isActive;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary700 : AppColors.textMuted;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => onTap?.call(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(icon: icon.data, color: color, size: 22, strokeWidth: 1.8),
          ],
        ),
      ),
    );
  }
}

class _CenterAction extends StatelessWidget {
  const _CenterAction({required this.isActive, required this.onTap});

  final bool isActive;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(40),
      onTap: () => onTap?.call(2),
      child: Container(
        height: 54,
        width: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary600,
          border: Border.all(
            color: AppColors.surface.withAlpha((0.35 * 255).round()),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary700.withAlpha((0.35 * 255).round()),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: AppColors.text.withAlpha((0.12 * 255).round()),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const OQIcon(
          OQIcon.autoAwesomeRounded,
          color: AppColors.surface,
          size: 24,
        ),
      ),
    );
  }
}
