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
        return SizedBox(
          height: 26,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: List.generate(22, (index) {
              final phase = (_controller.value * 2 * math.pi) + (index * 0.55);
              final amplitude = math.sin(phase).abs();
              final baseFactor = index.isEven ? 1.0 : 0.65;
              final height = 4 + (18 * amplitude * baseFactor);
              final alpha = (0.35 + (0.65 * amplitude)).clamp(0.0, 1.0);

              return Container(
                width: 3,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: widget.color.withAlpha((alpha * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
