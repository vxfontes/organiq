import 'dart:math' as math;

import 'package:flutter/material.dart';

class VoiceReactiveWave extends StatefulWidget {
  const VoiceReactiveWave({super.key, required this.color});

  final Color color;

  @override
  State<VoiceReactiveWave> createState() => VoiceReactiveWaveState();
}

class VoiceReactiveWaveState extends State<VoiceReactiveWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 920),
  )..repeat();

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
        return LayoutBuilder(
          builder: (context, constraints) {
            const barWidth = 3.0;
            const barSpacing = 2.0;
            const minBars = 6;
            const maxBars = 22;
            const defaultHeight = 26.0;
            const barStride = barWidth + barSpacing;
            final availableWidth = constraints.hasBoundedWidth
                ? constraints.maxWidth
                : maxBars * barStride;
            final waveHeight = constraints.hasBoundedHeight
                ? constraints.maxHeight
                : defaultHeight;

            var barCount = (availableWidth / barStride).floor();
            barCount = math.max(minBars, math.min(maxBars, barCount));

            final minBarHeight = math.max(2.0, waveHeight * 0.16);
            final maxBarHeight = math.max(minBarHeight + 2.0, waveHeight);

            return ClipRect(
              child: SizedBox(
                height: waveHeight,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(barCount, (index) {
                      final phase =
                          (_controller.value * 2 * math.pi) + (index * 0.55);
                      final amplitude = math.sin(phase).abs();
                      final baseFactor = index.isEven ? 1.0 : 0.65;
                      final height =
                          minBarHeight +
                          ((maxBarHeight - minBarHeight) *
                              amplitude *
                              baseFactor);
                      final alpha = (0.35 + (0.65 * amplitude)).clamp(0.0, 1.0);

                      return Container(
                        width: barWidth,
                        height: height,
                        margin: const EdgeInsets.symmetric(
                          horizontal: barSpacing / 2,
                        ),
                        decoration: BoxDecoration(
                          color: widget.color.withAlpha((alpha * 255).round()),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
