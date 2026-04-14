import 'package:flutter/widgets.dart';

enum TutorialStepKind { fullScreen, coachMark }

enum TutorialTabTarget { none, home, schedule, create, shopping, events, reminders }

enum BubblePosition { above, below, left, right, center }

enum HighlightShape { roundedRect, circle, fullScreen }

class TutorialHeroCta {
  const TutorialHeroCta({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;
}

class TutorialStep {
  const TutorialStep({
    required this.id,
    required this.groupId,
    required this.kind,
    required this.title,
    required this.body,
    this.targetKey,
    this.tabTarget = TutorialTabTarget.none,
    this.routeTarget,
    this.pushRoute,
    this.spotlightPadding = const EdgeInsets.all(8),
    this.bubblePosition = BubblePosition.below,
    this.highlightShape = HighlightShape.roundedRect,
    this.onBeforeShow,
    this.heroCta,
  });

  final String id;
  final String groupId;
  final TutorialStepKind kind;
  final String title;
  final String body;
  final GlobalKey? targetKey;
  final TutorialTabTarget tabTarget;
  /// Navigate via replace (Modular.navigate) — disposes current module.
  final String? routeTarget;
  /// Navigate via push (Modular.pushNamed) — keeps current module alive.
  final String? pushRoute;
  final EdgeInsets spotlightPadding;
  final BubblePosition bubblePosition;
  final HighlightShape highlightShape;
  final Future<void> Function()? onBeforeShow;
  final TutorialHeroCta? heroCta;
}
