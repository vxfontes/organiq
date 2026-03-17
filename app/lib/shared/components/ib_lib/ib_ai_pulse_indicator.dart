import 'package:flutter/material.dart';
import 'package:inbota/shared/components/ib_lib/ib_text.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class IBAIPulseIndicator extends StatefulWidget {
  const IBAIPulseIndicator({
    super.key,
    required this.message,
    this.progress,
    this.isActive = true,
  });

  final String message;
  final double? progress;
  final bool isActive;

  @override
  State<IBAIPulseIndicator> createState() => _IBAIPulseIndicatorState();
}

class _IBAIPulseIndicatorState extends State<IBAIPulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(IBAIPulseIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
    }
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
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.ai50,
                Color.lerp(
                  AppColors.ai100,
                  AppColors.ai50,
                  _controller.value,
                )!,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Color.lerp(
                AppColors.ai200,
                AppColors.ai600,
                _controller.value,
              )!,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _WaveIndicator(
                    isAnimating: widget.isActive,
                    animation: _controller,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: IBText(
                      widget.message,
                      context: context,
                    ).caption.color(AppColors.ai700).build(),
                  ),
                  if (widget.progress != null) ...[
                    const SizedBox(width: 8),
                    IBText(
                      '${(widget.progress! * 100).toInt()}%',
                      context: context,
                    ).caption.color(AppColors.ai600).build(),
                  ],
                ],
              ),
              if (widget.progress != null) ...[
                const SizedBox(height: 10),
                _GradientProgressBar(progress: widget.progress!),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _WaveIndicator extends StatelessWidget {
  const _WaveIndicator({
    required this.isAnimating,
    required this.animation,
  });

  final bool isAnimating;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _WavePainter(
          progress: animation.value,
          isAnimating: isAnimating,
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.progress,
    required this.isAnimating,
  });

  final double progress;
  final bool isAnimating;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.35;

    if (isAnimating) {
      final outerRadius = baseRadius + (progress * 4);
      final outerPaint = Paint()
        ..color = AppColors.ai600.withAlpha(
          ((1 - progress) * 255 * 0.3).round(),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(center, outerRadius, outerPaint);
    }

    final innerPaint = Paint()
      ..color = AppColors.ai600
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, baseRadius * 0.6, innerPaint);

    final highlightPaint = Paint()
      ..color = AppColors.ai500
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(center.dx - 2, center.dy - 2),
      baseRadius * 0.25,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isAnimating != isAnimating;
  }
}

class _GradientProgressBar extends StatelessWidget {
  const _GradientProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: AppColors.ai200,
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.ai500, AppColors.ai600],
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
