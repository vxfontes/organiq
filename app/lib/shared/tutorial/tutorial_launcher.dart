import 'package:flutter/material.dart';

import 'tutorial_controller.dart';
import 'tutorial_overlay.dart';
import 'tutorial_service.dart';

class TutorialLauncher {
  TutorialLauncher._();

  static OverlayEntry? _entry;

  static Future<void> launchIfNeeded({
    required BuildContext context,
    required TutorialController controller,
    required TutorialService service,
  }) async {
    if (service.isCompleted || service.isDismissed) return;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!context.mounted) return;
    _insertOverlayInto(Overlay.of(context), controller);
    await controller.start();
  }

  static Future<void> relaunch({
    required BuildContext context,
    required TutorialController controller,
    required TutorialService service,
  }) async {
    await service.resetTutorial();
    if (!context.mounted) return;
    _insertOverlayInto(Overlay.of(context), controller);
    await controller.start();
  }

  /// Relaunch using a pre-captured [OverlayState], safe to use across async
  /// gaps since OverlayState itself does not carry a BuildContext safety check.
  static Future<void> relaunchWithOverlay({
    required OverlayState overlayState,
    required TutorialController controller,
    required TutorialService service,
  }) async {
    await service.resetTutorial();
    _insertOverlayInto(overlayState, controller);
    await controller.start();
  }

  static void _insertOverlayInto(
    OverlayState overlayState,
    TutorialController controller,
  ) {
    _entry?.remove();
    _entry = null;

    void listener() {
      if (!controller.isActive) {
        _entry?.remove();
        _entry = null;
        controller.removeListener(listener);
      }
    }

    controller.addListener(listener);

    _entry = OverlayEntry(
      builder: (_) => TutorialOverlay(controller: controller),
    );

    overlayState.insert(_entry!);
  }
}
