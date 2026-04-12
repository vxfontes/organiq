import 'dart:math';

import 'package:flutter/material.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class NightSkyPainter extends CustomPainter {
  static final Random _random = Random(42);

  @override
  void paint(Canvas canvas, Size size) {
    _drawNightSky(canvas, size);
    _drawStars(canvas, size);
    _drawMoon(canvas, size);
    _drawNightClouds(canvas, size);
  }

  void _drawNightSky(Canvas canvas, Size size) {
    const skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.skyNightTop, AppColors.skyNightBottom],
    );

    final skyPaint = Paint()
      ..shader = skyGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);
  }

  void _drawStars(Canvas canvas, Size size) {
    final starPositions = [
      Offset(size.width * 0.05, size.height * 0.08),
      Offset(size.width * 0.12, size.height * 0.15),
      Offset(size.width * 0.08, size.height * 0.25),
      Offset(size.width * 0.18, size.height * 0.05),
      Offset(size.width * 0.25, size.height * 0.18),
      Offset(size.width * 0.32, size.height * 0.1),
      Offset(size.width * 0.38, size.height * 0.22),
      Offset(size.width * 0.48, size.height * 0.08),
      Offset(size.width * 0.55, size.height * 0.15),
      Offset(size.width * 0.62, size.height * 0.05),
      Offset(size.width * 0.68, size.height * 0.2),
      Offset(size.width * 0.75, size.height * 0.12),
      Offset(size.width * 0.82, size.height * 0.25),
      Offset(size.width * 0.88, size.height * 0.1),
      Offset(size.width * 0.92, size.height * 0.18),
      Offset(size.width * 0.15, size.height * 0.35),
      Offset(size.width * 0.28, size.height * 0.32),
      Offset(size.width * 0.42, size.height * 0.35),
      Offset(size.width * 0.58, size.height * 0.3),
      Offset(size.width * 0.72, size.height * 0.38),
      Offset(size.width * 0.85, size.height * 0.35),
    ];

    for (final position in starPositions) {
      _drawStar(canvas, position, 1.5 + _random.nextDouble() * 1.5);
    }

    _drawShootingStar(canvas, size);
  }

  void _drawStar(Canvas canvas, Offset position, double size) {
    final isBigStar = size > 2;

    final starColor = isBigStar ? AppColors.starYellow : AppColors.starWhite;

    final glowPaint = Paint()
      ..color = starColor.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawCircle(position, size * 1.5, glowPaint);

    final starPaint = Paint()
      ..color = starColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, size, starPaint);

    if (isBigStar) {
      final twinklePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(position.dx - size * 0.3, position.dy - size * 0.3),
        size * 0.3,
        twinklePaint,
      );
    }
  }

  void _drawShootingStar(Canvas canvas, Size size) {
    final startPoint = Offset(size.width * 0.55, size.height * 0.12);
    final endPoint = Offset(size.width * 0.45, size.height * 0.18);

    final gradient = LinearGradient(
      colors: [
        AppColors.starWhite.withValues(alpha: 0.0),
        AppColors.starWhite.withValues(alpha: 0.8),
        AppColors.starWhite,
      ],
    );

    final starPaint = Paint()
      ..shader = gradient.createShader(Rect.fromPoints(startPoint, endPoint))
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(startPoint, endPoint, starPaint);
  }

  void _drawMoon(Canvas canvas, Size size) {
    final moonCenter = Offset(size.width * 0.2, size.height * 0.2);
    final moonRadius = size.width * 0.08;

    final moonGlowGradient = RadialGradient(
      colors: [
        AppColors.moonYellow.withValues(alpha: 0.4),
        AppColors.moonYellow.withValues(alpha: 0.0),
      ],
    );

    final glowPaint = Paint()
      ..shader = moonGlowGradient.createShader(
        Rect.fromCircle(center: moonCenter, radius: moonRadius * 2.5),
      );

    canvas.drawCircle(moonCenter, moonRadius * 2.5, glowPaint);

    final moonPaint = Paint()
      ..color = AppColors.moonYellow
      ..style = PaintingStyle.fill;

    canvas.drawCircle(moonCenter, moonRadius, moonPaint);

    final craterPaint = Paint()
      ..color = const Color(0xFFD97706).withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(
        moonCenter.dx - moonRadius * 0.3,
        moonCenter.dy - moonRadius * 0.2,
      ),
      moonRadius * 0.2,
      craterPaint,
    );

    canvas.drawCircle(
      Offset(
        moonCenter.dx + moonRadius * 0.2,
        moonCenter.dy + moonRadius * 0.3,
      ),
      moonRadius * 0.15,
      craterPaint,
    );

    canvas.drawCircle(
      Offset(
        moonCenter.dx + moonRadius * 0.4,
        moonCenter.dy - moonRadius * 0.3,
      ),
      moonRadius * 0.1,
      craterPaint,
    );
  }

  void _drawNightClouds(Canvas canvas, Size size) {
    _drawNightCloud(
      canvas,
      Offset(size.width * 0.1, size.height * 0.45),
      size.width * 0.25,
      0.4,
    );

    _drawNightCloud(
      canvas,
      Offset(size.width * 0.4, size.height * 0.55),
      size.width * 0.3,
      0.35,
    );

    _drawNightCloud(
      canvas,
      Offset(size.width * 0.75, size.height * 0.48),
      size.width * 0.22,
      0.5,
    );

    _drawNightCloud(
      canvas,
      Offset(size.width * 0.55, size.height * 0.72),
      size.width * 0.28,
      0.3,
    );

    _drawNightCloud(
      canvas,
      Offset(size.width * 0.2, size.height * 0.7),
      size.width * 0.2,
      0.25,
    );
  }

  void _drawNightCloud(
    Canvas canvas,
    Offset position,
    double size,
    double opacity,
  ) {
    final cloudPaint = Paint()
      ..color = AppColors.nightCloud.withValues(alpha: opacity * 0.6)
      ..style = PaintingStyle.fill;

    final highlightPaint = Paint()
      ..color = const Color(0xFF6366F1).withValues(alpha: opacity * 0.4)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(position.dx - size * 0.25, position.dy),
      size * 0.4,
      cloudPaint,
    );

    canvas.drawCircle(
      Offset(position.dx + size * 0.2, position.dy - size * 0.1),
      size * 0.45,
      cloudPaint,
    );

    canvas.drawCircle(
      Offset(position.dx + size * 0.45, position.dy + size * 0.05),
      size * 0.35,
      cloudPaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(position.dx + size * 0.1, position.dy + size * 0.15),
        width: size * 1.1,
        height: size * 0.45,
      ),
      cloudPaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(position.dx + size * 0.15, position.dy - size * 0.05),
        width: size * 0.6,
        height: size * 0.25,
      ),
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
