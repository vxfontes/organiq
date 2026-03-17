import 'dart:math';

import 'package:flutter/material.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class MorningSkyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    _drawSky(canvas, size);
    _drawSun(canvas, size);
    _drawClouds(canvas, size);
  }

  void _drawSky(Canvas canvas, Size size) {
    const skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.skyMorningTop, AppColors.skyMorningBottom],
    );

    final skyPaint = Paint()
      ..shader = skyGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);
  }

  void _drawSun(Canvas canvas, Size size) {
    final sunCenter = Offset(size.width * 0.75, size.height * 0.25);
    final sunRadius = size.width * 0.12;

    final sunGlowGradient = RadialGradient(
      colors: [
        AppColors.sunYellow.withValues(alpha: 0.8),
        AppColors.sunOrange.withValues(alpha: 0.3),
        AppColors.sunOrange.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final glowPaint = Paint()
      ..shader = sunGlowGradient.createShader(
        Rect.fromCircle(center: sunCenter, radius: sunRadius * 2.5),
      );

    canvas.drawCircle(sunCenter, sunRadius * 2.5, glowPaint);

    final sunPaint = Paint()
      ..color = AppColors.sunYellow
      ..style = PaintingStyle.fill;

    canvas.drawCircle(sunCenter, sunRadius, sunPaint);

    final sunInnerPaint = Paint()
      ..color = const Color(0xFFFEF3C7)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(sunCenter, sunRadius * 0.7, sunInnerPaint);

    _drawSunRays(canvas, sunCenter, sunRadius);
  }

  void _drawSunRays(Canvas canvas, Offset center, double radius) {
    final rayPaint = Paint()
      ..color = AppColors.sunYellow.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const rayCount = 8;
    final rayLength = radius * 0.4;

    for (int i = 0; i < rayCount; i++) {
      final angle = (i * 2 * pi / rayCount) - pi / 2;
      final startPoint = Offset(
        center.dx + (radius * 1.1) * cos(angle),
        center.dy + (radius * 1.1) * sin(angle),
      );
      final endPoint = Offset(
        center.dx + (radius * 1.1 + rayLength) * cos(angle),
        center.dy + (radius * 1.1 + rayLength) * sin(angle),
      );

      canvas.drawLine(startPoint, endPoint, rayPaint);
    }
  }

  void _drawClouds(Canvas canvas, Size size) {
    _drawCloud(
      canvas,
      Offset(size.width * 0.1, size.height * 0.55),
      size.width * 0.32,
      0.7,
    );

    _drawCloud(
      canvas,
      Offset(size.width * 0.35, size.height * 0.3),
      size.width * 0.12,
      0.85,
    );

    _drawCloud(
      canvas,
      Offset(size.width * 0.6, size.height * 0.7),
      size.width * 0.15,
      0.6,
    );

    _drawCloud(
      canvas,
      Offset(size.width * 0.85, size.height * 0.45),
      size.width * 0.12,
      0.5,
    );

    _drawCloud(
      canvas,
      Offset(size.width * 0.5, size.height * 0.85),
      size.width * 0.2,
      0.4,
    );
  }

  void _drawCloud(Canvas canvas, Offset position, double size, double opacity) {
    final cloudColor = Color.lerp(
      AppColors.cloudWhite,
      AppColors.cloudGray,
      1 - opacity,
    )!;

    final cloudPaint = Paint()
      ..color = cloudColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = AppColors.cloudGray.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(position.dx, position.dy + size * 0.1),
      size * 0.5,
      shadowPaint,
    );

    canvas.drawCircle(
      Offset(position.dx - size * 0.3, position.dy),
      size * 0.4,
      cloudPaint,
    );

    canvas.drawCircle(
      Offset(position.dx + size * 0.25, position.dy - size * 0.1),
      size * 0.45,
      cloudPaint,
    );

    canvas.drawCircle(
      Offset(position.dx + size * 0.5, position.dy + size * 0.05),
      size * 0.35,
      cloudPaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(position.dx + size * 0.1, position.dy + size * 0.15),
        width: size * 1.2,
        height: size * 0.5,
      ),
      cloudPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
