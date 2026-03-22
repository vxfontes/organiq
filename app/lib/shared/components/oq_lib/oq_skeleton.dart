import 'package:flutter/material.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class OQSkeleton extends StatelessWidget {
  const OQSkeleton({
    super.key,
    this.width,
    required this.height,
    this.radius = 12,
    this.margin,
  });

  final double? width;
  final double height;
  final double radius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
