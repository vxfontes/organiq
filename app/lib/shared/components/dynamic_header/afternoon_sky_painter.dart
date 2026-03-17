import 'package:flutter/material.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class AfternoonSkyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    _drawSunsetSky(canvas, size);
    _drawSun(canvas, size);
    _drawClouds(canvas, size);
  }

  void _drawSunsetSky(Canvas canvas, Size size) {
    const skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.skyAfternoonTop,
        AppColors.sunsetPurple,
        AppColors.skyAfternoonMid,
        AppColors.skyAfternoonBottom,
      ],
      stops: [0.0, 0.3, 0.6, 1.0],
    );

    final skyPaint = Paint()
      ..shader = skyGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);
  }

  void _drawSun(Canvas canvas, Size size) {
    final sunCenter = Offset(size.width * 0.7, size.height * 0.55);
    final sunRadius = size.width * 0.15;

    final sunGlowGradient = RadialGradient(
      colors: [
        AppColors.sunYellow.withValues(alpha: 0.9),
        AppColors.sunsetOrange.withValues(alpha: 0.5),
        AppColors.sunsetOrange.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.4, 1.0],
    );

    final glowPaint = Paint()
      ..shader = sunGlowGradient.createShader(
        Rect.fromCircle(center: sunCenter, radius: sunRadius * 3),
      );

    canvas.drawCircle(sunCenter, sunRadius * 3, glowPaint);

    final sunPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.sunYellow, AppColors.sunsetOrange],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: sunRadius));

    canvas.drawCircle(sunCenter, sunRadius, sunPaint);
  }

  void _drawClouds(Canvas canvas, Size size) {
    _drawSunsetCloud(
      canvas,
      Offset(size.width * 0.1, size.height * 0.25),
      size.width * 0.12,
      0.4,
    );

    _drawSunsetCloud(
      canvas,
      Offset(size.width * 0.4, size.height * 0.15),
      size.width * 0.12,
      0.6,
    );

    _drawSunsetCloud(
      canvas,
      Offset(size.width * 0.85, size.height * 0.3),
      size.width * 0.09,
      0.5,
    );

    _drawSunsetCloud(
      canvas,
      Offset(size.width * 0.2, size.height * 0.5),
      size.width * 0.22,
      0.3,
    );

    _drawSunsetCloud(
      canvas,
      Offset(size.width * 0.6, size.height * 0.7),
      size.width * 0.15,
      0.42,
    );
  }

  void _drawSunsetCloud(
    Canvas canvas,
    Offset position,
    double size,
    double opacity,
  ) {
    final baseColor = Color.lerp(
      const Color(0xFFFDBA74),
      const Color(0xFFFB923C),
      opacity,
    )!;

    final cloudPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.8)
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
