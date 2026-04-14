import 'package:flutter/material.dart';

import 'package:organiq/shared/components/oq_lib/oq_button.dart';
import 'package:organiq/shared/components/oq_lib/oq_icon.dart';
import 'package:organiq/shared/components/oq_lib/oq_text.dart';
import 'package:organiq/shared/theme/app_colors.dart';

import 'tutorial_controller.dart';
import 'tutorial_step.dart';

class TutorialBubble extends StatelessWidget {
  const TutorialBubble({
    super.key,
    required this.controller,
    required this.step,
    required this.targetRect,
    required this.screenSize,
  });

  final TutorialController controller;
  final TutorialStep step;
  final Rect targetRect;
  final Size screenSize;

  static const double _bubbleWidth = 300;
  static const double _bubbleMinHeight = 160;
  static const double _arrowSize = 10;
  static const double _margin = 16;
  static const double _minSpaceRequired = 200;

  @override
  Widget build(BuildContext context) {
    final position = _resolvePosition(step.bubblePosition);
    final bubbleOffset = _calculateBubbleOffset(position);

    return Positioned(
      left: bubbleOffset.dx,
      top: bubbleOffset.dy,
      width: _bubbleWidth,
      child: _BubbleContent(
        controller: controller,
        step: step,
        position: position,
      ),
    );
  }

  BubblePosition _resolvePosition(BubblePosition requested) {
    if (requested == BubblePosition.below) {
      final spaceBelow = screenSize.height - targetRect.bottom;
      if (spaceBelow < _minSpaceRequired) return BubblePosition.above;
    }
    if (requested == BubblePosition.above) {
      final spaceAbove = targetRect.top;
      if (spaceAbove < _minSpaceRequired) return BubblePosition.below;
    }
    return requested;
  }

  Offset _calculateBubbleOffset(BubblePosition position) {
    double left = targetRect.center.dx - _bubbleWidth / 2;
    double top;

    // Clamp left to screen bounds
    left = left.clamp(_margin, screenSize.width - _bubbleWidth - _margin);

    switch (position) {
      case BubblePosition.below:
        top = targetRect.bottom + _arrowSize + 12;
        break;
      case BubblePosition.above:
        top = targetRect.top - _bubbleMinHeight - _arrowSize - 12;
        top = top.clamp(_margin, screenSize.height - _bubbleMinHeight - _margin);
        break;
      case BubblePosition.left:
        top = targetRect.center.dy - _bubbleMinHeight / 2;
        left = targetRect.left - _bubbleWidth - _arrowSize - 12;
        left = left.clamp(_margin, screenSize.width - _bubbleWidth - _margin);
        break;
      case BubblePosition.right:
        top = targetRect.center.dy - _bubbleMinHeight / 2;
        left = targetRect.right + _arrowSize + 12;
        left = left.clamp(_margin, screenSize.width - _bubbleWidth - _margin);
        break;
      case BubblePosition.center:
        top = screenSize.height / 2 - _bubbleMinHeight / 2;
        left = screenSize.width / 2 - _bubbleWidth / 2;
        break;
    }

    return Offset(left, top);
  }
}

class _BubbleContent extends StatelessWidget {
  const _BubbleContent({
    required this.controller,
    required this.step,
    required this.position,
  });

  final TutorialController controller;
  final TutorialStep step;
  final BubblePosition position;

  @override
  Widget build(BuildContext context) {
    final isFirst = controller.isFirstStep;
    final isLast = controller.isLastStep;
    final current = controller.currentIndex + 1;
    final total = controller.totalSteps;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row: counter + skip
            Row(
              children: [
                OQText('$current de $total', context: context)
                    .caption
                    .color(AppColors.textMuted)
                    .build(),
                const Spacer(),
                if (!isLast)
                  GestureDetector(
                    onTap: controller.skip,
                    child: OQText('Pular tutorial', context: context)
                        .caption
                        .color(AppColors.textMuted)
                        .build(),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // Title
            OQText(step.title, context: context).subtitulo.build(),
            const SizedBox(height: 6),
            // Body
            OQText(step.body, context: context).body.build(),
            const SizedBox(height: 16),
            // Footer buttons
            Row(
              children: [
                if (!isFirst) ...[
                  Expanded(
                    child: OQButton(
                      label: 'Anterior',
                      variant: OQButtonVariant.secondary,
                      onPressed: controller.previous,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: OQButton(
                    label: isLast ? 'Concluir' : 'Próximo',
                    variant: OQButtonVariant.primary,
                    onPressed: controller.next,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TutorialFullScreenStep extends StatelessWidget {
  const TutorialFullScreenStep({
    super.key,
    required this.controller,
    required this.step,
  });

  final TutorialController controller;
  final TutorialStep step;

  @override
  Widget build(BuildContext context) {
    final isFirst = controller.isFirstStep;
    final isLast = controller.isLastStep;
    final current = controller.currentIndex + 1;
    final total = controller.totalSteps;

    final isWelcome = step.id == 'welcome';
    final nextLabel = isWelcome ? 'Começar' : (isLast ? 'Concluir' : 'Próximo');

    return Container(
      color: const Color(0xF0000000),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon circle
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary600.withValues(alpha:0.2),
                    border: Border.all(
                      color: AppColors.primary500.withValues(alpha:0.4),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: OQIcon(
                      OQIcon.autoAwesomeRounded,
                      color: AppColors.primary200,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Title
              OQText(step.title, context: context)
                  .titulo
                  .color(Colors.white)
                  .align(TextAlign.center)
                  .build(),
              const SizedBox(height: 14),
              // Body
              OQText(step.body, context: context)
                  .body
                  .color(Colors.white.withValues(alpha: 0.82))
                  .align(TextAlign.center)
                  .build(),
              const SizedBox(height: 36),
              // CTA / navigation buttons
              if (step.heroCta != null) ...[
                OQButton(
                  label: step.heroCta!.label,
                  onPressed: () async {
                    // Finish/advance tutorial first so it is marked complete,
                    // then execute the CTA action (e.g. navigate to create).
                    await controller.next();
                    step.heroCta!.onTap();
                  },
                ),
                const SizedBox(height: 12),
                if (!isFirst)
                  OQButton(
                    label: 'Anterior',
                    variant: OQButtonVariant.secondary,
                    onPressed: controller.previous,
                  ),
              ] else ...[
                Row(
                  children: [
                    if (!isFirst) ...[
                      Expanded(
                        child: OQButton(
                          label: 'Anterior',
                          variant: OQButtonVariant.secondary,
                          onPressed: controller.previous,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: OQButton(
                        label: nextLabel,
                        onPressed: controller.next,
                      ),
                    ),
                  ],
                ),
              ],
              if (!isLast) ...[
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: controller.skip,
                    child: OQText('Pular tutorial', context: context)
                        .caption
                        .color(Colors.white.withValues(alpha: 0.5))
                        .build(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Step counter
              Center(
                child: OQText('$current de $total', context: context)
                    .caption
                    .color(Colors.white.withValues(alpha: 0.45))
                    .build(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
