import 'package:flutter/material.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class OQSkeleton extends StatefulWidget {
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
  State<OQSkeleton> createState() => _OQSkeletonState();
}

class _OQSkeletonState extends State<OQSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final color = Color.lerp(
          AppColors.surface2,
          AppColors.border,
          _controller.value,
        )!;

        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}
