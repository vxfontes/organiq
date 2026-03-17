import 'package:flutter/material.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary50,
                  AppColors.surfaceSoft,
                  AppColors.ai50,
                ],
                stops: [0.0, 0.52, 1.0],
              ),
            ),
          ),
        ),
        const Positioned(
          top: -140,
          left: -90,
          child: IgnorePointer(
            child: _GlowBlob(
              color: AppColors.primary200,
              size: 280,
            ),
          ),
        ),
        const Positioned(
          bottom: -160,
          right: -110,
          child: IgnorePointer(
            child: _GlowBlob(
              color: AppColors.ai100,
              size: 300,
            ),
          ),
        ),
        const Positioned(
          top: 160,
          right: -50,
          child: IgnorePointer(
            child: _GlowBlob(
              color: AppColors.warning500,
              size: 170,
              opacity: 0.18,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.color,
    required this.size,
    this.opacity = 0.2,
  });

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final glowColor = color.withAlpha((opacity * 255).round());
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: glowColor,
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: size * 0.55,
            spreadRadius: size * 0.12,
          ),
        ],
      ),
    );
  }
}
