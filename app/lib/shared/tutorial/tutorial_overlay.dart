import 'package:flutter/material.dart';

import 'tutorial_bubble.dart';
import 'tutorial_coach_mark.dart';
import 'tutorial_controller.dart';
import 'tutorial_step.dart';

class TutorialOverlay extends StatefulWidget {
  const TutorialOverlay({super.key, required this.controller});

  final TutorialController controller;

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    widget.controller.addListener(_onControllerChanged);
    if (widget.controller.isActive) {
      _animController.forward();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _animController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    if (widget.controller.isActive) {
      _animController.forward(from: 0);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    if (!controller.isActive) {
      return const SizedBox.shrink();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          controller.previous();
        }
      },
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildContent(context, controller),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TutorialController controller) {
    if (controller.isTransitioning) {
      return Container(
        color: const Color(0xAA000000),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
      );
    }

    final step = controller.currentStep;

    if (step.kind == TutorialStepKind.fullScreen) {
      return TutorialFullScreenStep(
        controller: controller,
        step: step,
      );
    }

    // CoachMark
    return _buildCoachMark(context, controller, step);
  }

  Widget _buildCoachMark(
    BuildContext context,
    TutorialController controller,
    TutorialStep step,
  ) {
    final targetKey = step.targetKey;
    if (targetKey == null) {
      return const SizedBox.shrink();
    }

    final renderBox =
        targetKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null || !renderBox.hasSize) {
      // Guard: target widget not mounted yet (e.g. page still showing a
      // loading skeleton). Schedule a rebuild on the next frame so that once
      // the target appears in the tree the coach mark renders correctly.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      return Container(
        color: const Color(0xCC000000),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
      );
    }

    final screenSize = MediaQuery.of(context).size;
    final position = renderBox.localToGlobal(Offset.zero);
    final targetRect = Rect.fromLTWH(
      position.dx,
      position.dy,
      renderBox.size.width,
      renderBox.size.height,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        // Dark overlay with spotlight cutout
        CustomPaint(
          painter: TutorialCoachMarkPainter(
            targetRect: targetRect,
            shape: step.highlightShape,
            spotlightPadding: step.spotlightPadding,
          ),
        ),
        // Info bubble
        TutorialBubble(
          controller: controller,
          step: step,
          targetRect: targetRect,
          screenSize: screenSize,
        ),
      ],
    );
  }
}
