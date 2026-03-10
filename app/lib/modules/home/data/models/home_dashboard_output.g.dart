// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_dashboard_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeDashboardOutput _$HomeDashboardOutputFromJson(
  Map<String, dynamic> json,
) => HomeDashboardOutput(
  dayProgress: HomeDashboardOutput._dayProgressFromJson(json['day_progress']),
  insight: HomeDashboardOutput._insightFromJson(json['insight']),
  timeline: json['timeline'] == null
      ? []
      : HomeDashboardOutput._timelineFromJson(json['timeline']),
  shoppingPreview: json['shopping_preview'] == null
      ? []
      : HomeDashboardOutput._shoppingPreviewFromJson(json['shopping_preview']),
  weekDensity: json['week_density'] == null
      ? {}
      : HomeDashboardOutput._weekDensityFromJson(json['week_density']),
  focusTasks: json['focus_tasks'] == null
      ? []
      : HomeDashboardOutput._focusTasksFromJson(json['focus_tasks']),
  eventsTodayCount: (json['events_today_count'] as num?)?.toInt(),
  remindersTodayCount: (json['reminders_today_count'] as num?)?.toInt(),
);

Map<String, dynamic> _$HomeDashboardOutputToJson(
  HomeDashboardOutput instance,
) => <String, dynamic>{
  'day_progress': instance.dayProgress,
  'insight': instance.insight,
  'timeline': instance.timeline,
  'shopping_preview': instance.shoppingPreview,
  'week_density': instance.weekDensity,
  'focus_tasks': instance.focusTasks,
  'events_today_count': instance.eventsTodayCount,
  'reminders_today_count': instance.remindersTodayCount,
};
