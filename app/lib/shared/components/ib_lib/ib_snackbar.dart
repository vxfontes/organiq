import 'package:flutter/material.dart';
import 'package:inbota/shared/theme/app_colors.dart';
import 'ib_text.dart';
import 'ib_icon.dart';

class IBSnackBar {
  IBSnackBar._();

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
            IBIcon(
              isError ? IBIcon.errorOutlineRounded : IBIcon.checkCircleOutlineRounded,
              color: AppColors.surface,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: IBText(message, context: context)
                  .label
                  .color(AppColors.surface)
                  .build(),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.danger600 : AppColors.primary700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
