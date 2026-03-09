import 'package:json_annotation/json_annotation.dart';

part 'notification_preferences_model.g.dart';

@JsonSerializable()
class NotificationPreferencesModel {
  @JsonKey(defaultValue: true)
  final bool remindersEnabled;
  @JsonKey(defaultValue: true)
  final bool reminderAtTime;
  @JsonKey(defaultValue: <int>[])
  final List<int> reminderLeadMins;

  @JsonKey(defaultValue: true)
  final bool eventsEnabled;
  @JsonKey(defaultValue: true)
  final bool eventAtTime;
  @JsonKey(defaultValue: <int>[])
  final List<int> eventLeadMins;

  @JsonKey(defaultValue: true)
  final bool tasksEnabled;
  @JsonKey(defaultValue: true)
  final bool taskAtTime;
  @JsonKey(defaultValue: <int>[])
  final List<int> taskLeadMins;

  @JsonKey(defaultValue: true)
  final bool routinesEnabled;
  @JsonKey(defaultValue: true)
  final bool routineAtTime;
  @JsonKey(defaultValue: <int>[])
  final List<int> routineLeadMins;

  @JsonKey(defaultValue: false)
  final bool quietHoursEnabled;
  final String? quietStart;  // "22:00"
  final String? quietEnd;    // "08:00"

  @JsonKey(defaultValue: false)
  final bool dailyDigestEnabled;
  @JsonKey(defaultValue: 4)
  final int dailyDigestHour;

  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime updatedAt;

  const NotificationPreferencesModel({
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
    required this.dailyDigestEnabled,
    required this.dailyDigestHour,
    required this.updatedAt,
  });

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return _$NotificationPreferencesModelFromJson(json);
  }

  factory NotificationPreferencesModel.fromMap(Map<String, dynamic> map) {
    return NotificationPreferencesModel.fromJson(map);
  }

  Map<String, dynamic> toJson() => _$NotificationPreferencesModelToJson(this);

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
      'dailyDigestEnabled': dailyDigestEnabled,
      'dailyDigestHour': dailyDigestHour,
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
    bool? dailyDigestEnabled,
    int? dailyDigestHour,
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
      dailyDigestEnabled: dailyDigestEnabled ?? this.dailyDigestEnabled,
      dailyDigestHour: dailyDigestHour ?? this.dailyDigestHour,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime _dateTimeFromJson(Object? value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.parse(value);
    return DateTime.now();
  }

  static String _dateTimeToJson(DateTime value) => value.toIso8601String();
}
