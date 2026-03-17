import 'package:flutter/material.dart';
import 'package:organiq/presentation/screens/create_module/components/voice_react_wave_component.dart';
import 'package:organiq/shared/components/oq_lib/index.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class CreateVoiceRecordingCard extends StatelessWidget {
  const CreateVoiceRecordingCard({super.key, required this.recordingSeconds});

  final int recordingSeconds;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.danger600.withAlpha((0.08 * 255).round()),
            AppColors.primary50,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.danger600.withAlpha((0.3 * 255).round()),
        ),
      ),
      child: Row(
        children: [
          const _PulsingMicIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OQText(
                  'Gravando',
                  context: context,
                ).label.color(AppColors.danger600).build(),
                const SizedBox(height: 2),
                OQText(
                  _formatRecordingTime(recordingSeconds),
                  context: context,
                ).caption.color(AppColors.textMuted).build(),
              ],
            ),
          ),
          const SizedBox(
            width: 60,
            height: 24,
            child: VoiceReactiveWave(color: AppColors.primary600),
          ),
        ],
      ),
    );
  }

  String _formatRecordingTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }
}

class _PulsingMicIcon extends StatefulWidget {
  const _PulsingMicIcon();

  @override
  State<_PulsingMicIcon> createState() => _PulsingMicIconState();
}

class _PulsingMicIconState extends State<_PulsingMicIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.danger600.withAlpha(
              ((0.1 + (_controller.value * 0.1)) * 255).round(),
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mic_rounded,
            color: AppColors.danger600,
            size: 20,
          ),
        );
      },
    );
  }
}
