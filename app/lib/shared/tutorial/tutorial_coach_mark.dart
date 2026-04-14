import 'package:flutter/material.dart';

import 'tutorial_step.dart';

class TutorialCoachMarkPainter extends CustomPainter {
  const TutorialCoachMarkPainter({
    required this.targetRect,
    required this.shape,
    required this.spotlightPadding,
  });

  final Rect targetRect;
  final HighlightShape shape;
  final EdgeInsets spotlightPadding;

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = const Color(0xCC000000);
    final clearPaint = Paint()..blendMode = BlendMode.clear;
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final paddedRect = Rect.fromLTRB(
      targetRect.left - spotlightPadding.left,
      targetRect.top - spotlightPadding.top,
      targetRect.right + spotlightPadding.right,
      targetRect.bottom + spotlightPadding.bottom,
    );

    // Draw overlay using saveLayer to support BlendMode.clear
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // Full-screen dark overlay
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      overlayPaint,
    );

    // Cut out the spotlight hole
    if (shape == HighlightShape.circle) {
      final center = paddedRect.center;
      final radius =
          (paddedRect.width > paddedRect.height
              ? paddedRect.width
              : paddedRect.height) /
          2;
      canvas.drawCircle(center, radius, clearPaint);
      canvas.restore();
      // Draw luminous border
      canvas.drawCircle(center, radius, borderPaint);
    } else {
      final rrect = RRect.fromRectAndRadius(
        paddedRect,
        const Radius.circular(14),
      );
      canvas.drawRRect(rrect, clearPaint);
      canvas.restore();
      // Draw luminous border
      canvas.drawRRect(rrect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(TutorialCoachMarkPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.shape != shape ||
        oldDelegate.spotlightPadding != spotlightPadding;
  }
}
