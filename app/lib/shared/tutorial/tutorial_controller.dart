import 'dart:async';

import 'package:flutter/widgets.dart';

import 'tutorial_service.dart';
import 'tutorial_step.dart';

class TutorialController extends ChangeNotifier {
  TutorialController({
    required TutorialService tutorialService,
    required List<TutorialStep> steps,
  })  : _service = tutorialService,
        _steps = steps;

  final TutorialService _service;
  final List<TutorialStep> _steps;

  int _currentIndex = 0;
  bool _isActive = false;
  bool _isTransitioning = false;

  // Callbacks injected by RootPage
  ValueChanged<int>? onTabChangeRequested;
  /// Uses Modular.navigate (replace) — disposes current module.
  ValueChanged<String>? onRouteChangeRequested;
  /// Uses Modular.pushNamed (stack) — keeps current module alive.
  ValueChanged<String>? onPushRouteRequested;
  /// Pops the topmost pushed route from the navigator stack.
  VoidCallback? onPopRouteRequested;

  bool _pushedRouteActive = false;

  bool get isActive => _isActive;
  bool get isTransitioning => _isTransitioning;
  int get currentIndex => _currentIndex;
  int get totalSteps => _steps.length;
  bool get isFirstStep => _currentIndex == 0;
  bool get isLastStep => _currentIndex == _steps.length - 1;

  TutorialStep get currentStep => _steps[_currentIndex];

  Future<void> start() async {
    final saved = _service.currentStep;
    _currentIndex = (saved < _steps.length) ? saved : 0;
    _isActive = true;
    notifyListeners();
    await _prepareCurrentStep();
  }

  Future<void> next() async {
    if (!_isActive) return;

    if (_currentIndex >= _steps.length - 1) {
      await _finish();
      return;
    }

    _isTransitioning = true;
    notifyListeners();

    _currentIndex++;
    await _service.saveStep(_currentIndex);

    await _prepareCurrentStep();

    _isTransitioning = false;
    notifyListeners();
  }

  Future<void> previous() async {
    if (!_isActive || _currentIndex == 0) return;

    _isTransitioning = true;
    notifyListeners();

    _currentIndex--;
    await _service.saveStep(_currentIndex);

    await _prepareCurrentStep();

    _isTransitioning = false;
    notifyListeners();
  }

  Future<void> skip() async {
    if (!_isActive) return;
    _popPushedRouteIfActive();
    await _service.markDismissed();
    _isActive = false;
    notifyListeners();
  }

  Future<void> _finish() async {
    _popPushedRouteIfActive();
    await _service.markCompleted();
    await _service.saveStep(0);
    _isActive = false;
    notifyListeners();
  }

  void _popPushedRouteIfActive() {
    if (_pushedRouteActive) {
      onPopRouteRequested?.call();
      _pushedRouteActive = false;
    }
  }

  Future<void> _prepareCurrentStep() async {
    final step = currentStep;

    // If a pushed route is active and this step doesn't push one, pop it first.
    if (_pushedRouteActive && step.pushRoute == null) {
      onPopRouteRequested?.call();
      _pushedRouteActive = false;
      await _waitForNextFrame();
      await _waitForNextFrame();
    }

    // Navigate to the required tab first
    if (step.tabTarget != TutorialTabTarget.none) {
      final tabIndex = _tabIndex(step.tabTarget);
      onTabChangeRequested?.call(tabIndex);
      await _waitForNextFrame();
      await _waitForNextFrame();
    }

    // Navigate via replace (disposes current module)
    if (step.routeTarget != null) {
      onRouteChangeRequested?.call(step.routeTarget!);
      await _waitForNextFrame();
      await _waitForNextFrame();
    }

    // Navigate via push (keeps current module alive)
    if (step.pushRoute != null && !_pushedRouteActive) {
      onPushRouteRequested?.call(step.pushRoute!);
      _pushedRouteActive = true;
      // Extra frames: pushed page initialises its module + triggers API fetch.
      // ~10 frames ≈ 166 ms at 60 fps — enough for most cached/fast responses.
      for (var i = 0; i < 10; i++) {
        await _waitForNextFrame();
      }
    }

    // Run custom pre-show callback
    if (step.onBeforeShow != null) {
      await step.onBeforeShow!();
    }

    // Wait two more frames to ensure widgets are laid out
    await _waitForNextFrame();
    await _waitForNextFrame();
  }

  int _tabIndex(TutorialTabTarget target) {
    switch (target) {
      case TutorialTabTarget.home:
        return 0;
      case TutorialTabTarget.schedule:
        return 1;
      case TutorialTabTarget.create:
        return 2;
      case TutorialTabTarget.shopping:
        return 3;
      case TutorialTabTarget.events:
        return 4;
      case TutorialTabTarget.reminders:
        // Reminders is accessed via route, not bottom nav tab index
        return 0;
      case TutorialTabTarget.none:
        return -1;
    }
  }

  Future<void> _waitForNextFrame() {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) => completer.complete());
    return completer.future;
  }
}
