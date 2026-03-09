// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_preferences_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationPreferencesModel _$NotificationPreferencesModelFromJson(
  Map<String, dynamic> json,
) => NotificationPreferencesModel(
  remindersEnabled: json['remindersEnabled'] as bool? ?? true,
  reminderAtTime: json['reminderAtTime'] as bool? ?? true,
  reminderLeadMins:
      (json['reminderLeadMins'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      [],
  eventsEnabled: json['eventsEnabled'] as bool? ?? true,
  eventAtTime: json['eventAtTime'] as bool? ?? true,
  eventLeadMins:
      (json['eventLeadMins'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      [],
  tasksEnabled: json['tasksEnabled'] as bool? ?? true,
  taskAtTime: json['taskAtTime'] as bool? ?? true,
  taskLeadMins:
      (json['taskLeadMins'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      [],
  routinesEnabled: json['routinesEnabled'] as bool? ?? true,
  routineAtTime: json['routineAtTime'] as bool? ?? true,
  routineLeadMins:
      (json['routineLeadMins'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      [],
  quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? false,
  quietStart: json['quietStart'] as String?,
  quietEnd: json['quietEnd'] as String?,
  dailyDigestEnabled: json['dailyDigestEnabled'] as bool? ?? false,
  dailyDigestHour: (json['dailyDigestHour'] as num?)?.toInt() ?? 4,
  updatedAt: NotificationPreferencesModel._dateTimeFromJson(json['updatedAt']),
);

Map<String, dynamic> _$NotificationPreferencesModelToJson(
  NotificationPreferencesModel instance,
) => <String, dynamic>{
  'remindersEnabled': instance.remindersEnabled,
  'reminderAtTime': instance.reminderAtTime,
  'reminderLeadMins': instance.reminderLeadMins,
  'eventsEnabled': instance.eventsEnabled,
  'eventAtTime': instance.eventAtTime,
  'eventLeadMins': instance.eventLeadMins,
  'tasksEnabled': instance.tasksEnabled,
  'taskAtTime': instance.taskAtTime,
  'taskLeadMins': instance.taskLeadMins,
  'routinesEnabled': instance.routinesEnabled,
  'routineAtTime': instance.routineAtTime,
  'routineLeadMins': instance.routineLeadMins,
  'quietHoursEnabled': instance.quietHoursEnabled,
  'quietStart': instance.quietStart,
  'quietEnd': instance.quietEnd,
  'dailyDigestEnabled': instance.dailyDigestEnabled,
  'dailyDigestHour': instance.dailyDigestHour,
  'updatedAt': NotificationPreferencesModel._dateTimeToJson(instance.updatedAt),
};
