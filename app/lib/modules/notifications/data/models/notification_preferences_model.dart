class NotificationPreferencesModel {
  final bool remindersEnabled;
  final bool reminderAtTime;
  final List<int> reminderLeadMins;

  final bool eventsEnabled;
  final bool eventAtTime;
  final List<int> eventLeadMins;

  final bool tasksEnabled;
  final bool taskAtTime;
  final List<int> taskLeadMins;

  final bool routinesEnabled;
  final bool routineAtTime;
  final List<int> routineLeadMins;

  final bool quietHoursEnabled;
  final String? quietStart;  // "22:00"
  final String? quietEnd;    // "08:00"
  final DateTime updatedAt;

  NotificationPreferencesModel({
    required this.remindersEnabled,
    required this.reminderAtTime,
    required this.reminderLeadMins,
    required this.eventsEnabled,
    required this.eventAtTime,
    required this.eventLeadMins,
    required this.tasksEnabled,
    required this.taskAtTime,
    required this.taskLeadMins,
    required this.routinesEnabled,
    required this.routineAtTime,
    required this.routineLeadMins,
    required this.quietHoursEnabled,
    this.quietStart,
    this.quietEnd,
    required this.updatedAt,
  });

  factory NotificationPreferencesModel.fromMap(Map<String, dynamic> map) {
    return NotificationPreferencesModel(
      remindersEnabled: map['remindersEnabled'] ?? true,
      reminderAtTime: map['reminderAtTime'] ?? true,
      reminderLeadMins: List<int>.from(map['reminderLeadMins'] ?? []),
      eventsEnabled: map['eventsEnabled'] ?? true,
      eventAtTime: map['eventAtTime'] ?? true,
      eventLeadMins: List<int>.from(map['eventLeadMins'] ?? []),
      tasksEnabled: map['tasksEnabled'] ?? true,
      taskAtTime: map['taskAtTime'] ?? true,
      taskLeadMins: List<int>.from(map['taskLeadMins'] ?? []),
      routinesEnabled: map['routinesEnabled'] ?? true,
      routineAtTime: map['routineAtTime'] ?? true,
      routineLeadMins: List<int>.from(map['routineLeadMins'] ?? []),
      quietHoursEnabled: map['quietHoursEnabled'] ?? false,
      quietStart: map['quietStart'],
      quietEnd: map['quietEnd'],
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'remindersEnabled': remindersEnabled,
      'reminderAtTime': reminderAtTime,
      'reminderLeadMins': reminderLeadMins,
      'eventsEnabled': eventsEnabled,
      'eventAtTime': eventAtTime,
      'eventLeadMins': eventLeadMins,
      'tasksEnabled': tasksEnabled,
      'taskAtTime': taskAtTime,
      'taskLeadMins': taskLeadMins,
      'routinesEnabled': routinesEnabled,
      'routineAtTime': routineAtTime,
      'routineLeadMins': routineLeadMins,
      'quietHoursEnabled': quietHoursEnabled,
      'quietStart': quietStart,
      'quietEnd': quietEnd,
    };
  }

  NotificationPreferencesModel copyWith({
    bool? remindersEnabled,
    bool? reminderAtTime,
    List<int>? reminderLeadMins,
    bool? eventsEnabled,
    bool? eventAtTime,
    List<int>? eventLeadMins,
    bool? tasksEnabled,
    bool? taskAtTime,
    List<int>? taskLeadMins,
    bool? routinesEnabled,
    bool? routineAtTime,
    List<int>? routineLeadMins,
    bool? quietHoursEnabled,
    String? quietStart,
    String? quietEnd,
    DateTime? updatedAt,
  }) {
    return NotificationPreferencesModel(
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderAtTime: reminderAtTime ?? this.reminderAtTime,
      reminderLeadMins: reminderLeadMins ?? this.reminderLeadMins,
      eventsEnabled: eventsEnabled ?? this.eventsEnabled,
      eventAtTime: eventAtTime ?? this.eventAtTime,
      eventLeadMins: eventLeadMins ?? this.eventLeadMins,
      tasksEnabled: tasksEnabled ?? this.tasksEnabled,
      taskAtTime: taskAtTime ?? this.taskAtTime,
      taskLeadMins: taskLeadMins ?? this.taskLeadMins,
      routinesEnabled: routinesEnabled ?? this.routinesEnabled,
      routineAtTime: routineAtTime ?? this.routineAtTime,
      routineLeadMins: routineLeadMins ?? this.routineLeadMins,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietStart: quietStart ?? this.quietStart,
      quietEnd: quietEnd ?? this.quietEnd,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
