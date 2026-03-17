import 'package:flutter/material.dart';
import 'package:organiq/shared/theme/app_colors.dart';
import 'oq_icon.dart';
import 'oq_text.dart';

class OQSnackBar {
  OQSnackBar._();

  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Remove current snackbar to show the new one immediately
    scaffoldMessenger.hideCurrentSnackBar();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            OQIcon(
              isError
                  ? OQIcon.errorOutlineRounded
                  : OQIcon.checkCircleOutlineRounded,
              color: AppColors.surface,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OQText(
                message,
                context: context,
              ).label.color(AppColors.surface).build(),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.danger600 : AppColors.primary700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void error(BuildContext context, String message) {
    show(context, message: message, isError: true);
  }

  static void success(BuildContext context, String message) {
    show(context, message: message, isError: false);
  }
}
