class AppPath {
  AppPath._();

  // API versioning
  static const String apiVersion = 'v1';
  static const String apiPrefix = '/$apiVersion';

  // Infra
  static const String healthz = '/healthz';

  // Auth
  static const String auth = '/auth';
  static const String authLogin = '$auth/login';
  static const String authSignup = '$auth/signup';
  static const String me = '/me';

  // Flags
  static const String flags = '/flags';
  static String flagById(String id) => '$flags/$id';
  static String flagSubflags(String flagId) => '$flags/$flagId/subflags';
  static const String subflags = '/subflags';
  static String subflagById(String id) => '$subflags/$id';

  // Inbox
  static const String inboxItems = '/inbox-items';
  static String inboxReprocess(String id) => '$inboxItems/$id/reprocess';
  static String inboxConfirm(String id) => '$inboxItems/$id/confirm';
  static String inboxDismiss(String id) => '$inboxItems/$id/dismiss';

  // Tasks
  static const String tasks = '/tasks';
  static String taskById(String id) => '$tasks/$id';

  // Reminders
  static const String reminders = '/reminders';
  static String reminderById(String id) => '$reminders/$id';

  // Events / agenda
  static const String events = '/events';
  static String eventById(String id) => '$events/$id';
  static const String agenda = '/agenda';
  static const String homeDashboard = '/home/dashboard';

  // Shopping
  static const String shoppingLists = '/shopping-lists';
  static String shoppingListById(String id) => '$shoppingLists/$id';
  static String shoppingListItems(String listId) =>
      '$shoppingLists/$listId/items';

  static const String shoppingItems = '/shopping-items';
  static String shoppingItemById(String id) => '$shoppingItems/$id';

  // Routines
  static const String routines = '/routines';
  static String routineById(String id) => '$routines/$id';
  static String routineToggle(String id) => '$routines/$id/toggle';
  static String routineDay(int weekday) => '$routines/day/$weekday';
  static const String routineTodaySummary = '/routines/today/summary';
  static String routineComplete(String id) => '$routines/$id/complete';
  static String routineCompleteByDate(String id, String date) =>
      '$routines/$id/complete/$date';
  static String routineHistory(String id) => '$routines/$id/history';
  static String routineStreak(String id) => '$routines/$id/streak';
  static String routineExceptions(String id) => '$routines/$id/exceptions';
  static String routineExceptionByDate(String id, String date) =>
      '$routines/$id/exceptions/$date';

  // Notifications
  static const String notificationPreferences = '/notification-preferences';
  static const String notifications = '/notifications';
  static const String notificationTest = '$notifications/test';
  static String notificationRead(String id) => '$notifications/$id/read';
  static const String notificationsReadAll = '$notifications/read-all';

  // Digest
  static const String digestTest = '/digest/test';
  static const String dailySummary = '/daily-summary'; // public (token)

  // Notification prefs extra
  static const String dailySummaryToken =
      '/notification-preferences/daily-summary-token';
  static const String dailySummaryTokenRotate =
      '/notification-preferences/daily-summary-token/rotate';

  // Devices
  static const String deviceToken = '/devices/token';
}
