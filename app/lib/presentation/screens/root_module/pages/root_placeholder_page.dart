import 'package:flutter/material.dart';
import 'package:organiq/shared/components/oq_lib/oq_text.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class RootPlaceholderPage extends StatelessWidget {
  const RootPlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: OQText(
          title,
          context: context,
        ).titulo.color(AppColors.textMuted).build(),
      ),
    );
  }
}
