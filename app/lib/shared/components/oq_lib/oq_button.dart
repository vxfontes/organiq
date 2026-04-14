import 'package:flutter/material.dart';
import 'package:organiq/shared/components/oq_lib/oq_text.dart';
import 'package:organiq/shared/theme/app_colors.dart';

enum OQButtonVariant { primary, secondary, ghost, ghostAi }

class OQButton extends StatelessWidget {
  const OQButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = OQButtonVariant.primary,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final OQButtonVariant variant;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || loading;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    const padding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
    const minimumSize = Size.fromHeight(48);

    switch (variant) {
      case OQButtonVariant.primary:
        return ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary700,
            foregroundColor: AppColors.surface,
            padding: padding,
            minimumSize: minimumSize,
            shape: shape,
            elevation: 0,
            disabledBackgroundColor: AppColors.primary700.withAlpha(
              (0.4 * 255).round(),
            ),
            disabledForegroundColor: AppColors.surface.withAlpha(
              (0.85 * 255).round(),
            ),
          ),
          child: loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.surface,
                  ),
                )
              : OQText(
                  label,
                  context: context,
                ).label.color(AppColors.surface).build(),
        );
      case OQButtonVariant.secondary:
        return OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary600,
            backgroundColor: AppColors.primary600.withAlpha(
              (0.08 * 255).round(),
            ),
            side: const BorderSide(color: AppColors.primary600),
            padding: padding,
            minimumSize: minimumSize,
            shape: shape,
            disabledForegroundColor: AppColors.primary600.withAlpha(
              (0.6 * 255).round(),
            ),
          ),
          child: loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary600,
                  ),
                )
              : OQText(
                  label,
                  context: context,
                ).label.color(AppColors.primary600).build(),
        );
      case OQButtonVariant.ghost:
        return TextButton(
          onPressed: isDisabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary700,
            padding: padding,
            minimumSize: minimumSize,
            shape: shape,
            disabledForegroundColor: AppColors.primary700.withAlpha(
              (0.6 * 255).round(),
            ),
          ),
          child: loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary700,
                  ),
                )
              : OQText(
                  label,
                  context: context,
                ).label.color(AppColors.primary700).build(),
        );
      case OQButtonVariant.ghostAi:
        return TextButton(
          onPressed: isDisabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.ai600,
            padding: padding,
            minimumSize: minimumSize,
            shape: shape,
            disabledForegroundColor: AppColors.ai600.withAlpha(
              (0.6 * 255).round(),
            ),
          ),
          child: loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.ai600,
                  ),
                )
              : OQText(
                  label,
                  context: context,
                ).label.color(AppColors.ai600).build(),
        );
    }
  }
}
