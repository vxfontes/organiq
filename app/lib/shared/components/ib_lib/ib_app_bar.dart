import 'package:flutter/material.dart';
import 'package:organiq/shared/components/ib_lib/ib_icon.dart';
import 'package:organiq/shared/components/ib_lib/ib_text.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class IBAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool centerTitle;
  final EdgeInsetsGeometry? padding;

  const IBAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = false,
    this.subtitle = "Seu dia mais leve",
    this.padding,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: kToolbarHeight + 16,
      title: Padding(
        padding: padding ?? const EdgeInsets.all(0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface.withAlpha((0.18 * 255).round()),
                border: Border.all(color: AppColors.surface.withAlpha((0.35 * 255).round())),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.text.withAlpha((0.14 * 255).round()),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const IBIcon(
                IBIcon.autoAwesomeRounded,
                color: AppColors.surface,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IBText(title, context: context)
                    .titulo
                    .color(AppColors.surface)
                    .build(),
                IBText(subtitle!, context: context)
                    .label
                    .color(AppColors.surface.withAlpha((0.78 * 255).round()))
                    .build(),
              ],
            ),
          ],
        ),
      ),
      centerTitle: centerTitle,
      actions: actions,
      elevation: 0,
      backgroundColor: AppColors.transparent,
      flexibleSpace: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary700,
                AppColors.primary600,
                AppColors.primary500,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class IBLightAppBar extends StatelessWidget implements PreferredSizeWidget {
  const IBLightAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: kToolbarHeight + 8,
      backgroundColor: AppColors.surface,
      elevation: 0,
      centerTitle: false,
      leadingWidth: 56,
      actions: actions,
      flexibleSpace: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
          ),
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: InkWell(
          onTap: onBack ?? () => Navigator.of(context).maybePop(),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary700,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary700.withAlpha((0.25 * 255).round()),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const IBIcon(
              IBIcon.arrowBackRounded,
              size: 18,
              color: AppColors.surface,
            ),
          ),
        ),
      ),
      title: IBText(title, context: context).titulo.build(),
    );
  }
}
