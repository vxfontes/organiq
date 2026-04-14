import 'package:organiq/shared/storage/app_preferences.dart';

class TutorialService {
  static const _keyCompleted = 'tutorial_v1_completed';
  static const _keyStep = 'tutorial_v1_current_step';
  static const _keyDismissed = 'tutorial_v1_dismissed';

  bool get isCompleted =>
      AppPreferences.instance.getBool(_keyCompleted) ?? false;

  bool get isDismissed =>
      AppPreferences.instance.getBool(_keyDismissed) ?? false;

  int get currentStep =>
      AppPreferences.instance.getInt(_keyStep) ?? 0;

  Future<void> markCompleted() async =>
      AppPreferences.instance.setBool(_keyCompleted, true);

  Future<void> markDismissed() async =>
      AppPreferences.instance.setBool(_keyDismissed, true);

  Future<void> saveStep(int step) async =>
      AppPreferences.instance.setInt(_keyStep, step);

  Future<void> resetTutorial() async {
    await AppPreferences.instance.remove(_keyCompleted);
    await AppPreferences.instance.remove(_keyDismissed);
    await AppPreferences.instance.remove(_keyStep);
  }
}
