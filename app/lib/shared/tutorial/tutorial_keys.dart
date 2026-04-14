import 'package:flutter/widgets.dart';

class TutorialKeys {
  TutorialKeys._();

  // Home
  static final homeQuickAddBar = GlobalKey(debugLabel: 'tut_quickAddBar');
  static final homeCarousel = GlobalKey(debugLabel: 'tut_carousel');
  static final homeBentoRow = GlobalKey(debugLabel: 'tut_bentoRow');

  // Root AppBar
  static final appBarSettings = GlobalKey(debugLabel: 'tut_settings');
  static final appBarNotifications = GlobalKey(debugLabel: 'tut_notifications');

  // Bottom Nav
  static final navHome = GlobalKey(debugLabel: 'tut_navHome');
  static final navSchedule = GlobalKey(debugLabel: 'tut_navSchedule');
  static final navCreate = GlobalKey(debugLabel: 'tut_navCreate');
  static final navShopping = GlobalKey(debugLabel: 'tut_navShopping');
  static final navEvents = GlobalKey(debugLabel: 'tut_navEvents');

  // Create
  static final createTextArea = GlobalKey(debugLabel: 'tut_createText');
  static final createModeSelector = GlobalKey(debugLabel: 'tut_modeSelector');
  static final createVoiceButton = GlobalKey(debugLabel: 'tut_voiceBtn');
  static final createReviewArea = GlobalKey(debugLabel: 'tut_reviewArea');

  // Events
  static final eventsCalendarStrip = GlobalKey(debugLabel: 'tut_calStrip');
  static final eventsFilters = GlobalKey(debugLabel: 'tut_eventFilters');

  // Schedule
  static final scheduleWeekDays = GlobalKey(debugLabel: 'tut_weekDays');
  static final scheduleRoutineCard = GlobalKey(debugLabel: 'tut_routineCard');

  // Shopping
  static final shoppingHeader = GlobalKey(debugLabel: 'tut_shoppingHdr');

  // Reminders
  static final remindersSection = GlobalKey(debugLabel: 'tut_reminders');
}
