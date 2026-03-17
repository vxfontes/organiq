import 'package:flutter/material.dart';
import 'package:organiq/shared/components/ib_lib/index.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class SettingsAccordionSection extends StatelessWidget {
  const SettingsAccordionSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.collapsedSummary,
    required this.icon,
    required this.isExpanded,
    required this.onTap,
    required this.child,
  });

  final String title;
  final String subtitle;
  final String collapsedSummary;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IBCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IBIcon(
                      icon,
                      size: 18,
                      color: AppColors.primary700,
                      backgroundColor: AppColors.surfaceSoft,
                      borderColor: AppColors.primary200,
                      padding: const EdgeInsets.all(9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IBText(title, context: context).subtitulo.build(),
                          const SizedBox(height: 2),
                          IBText(
                            isExpanded ? subtitle : collapsedSummary,
                            context: context,
                          ).caption.build(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 180),
                      turns: isExpanded ? 0.5 : 0,
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Divider(height: 1, thickness: 1),
                      Padding(padding: const EdgeInsets.all(14), child: child),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
