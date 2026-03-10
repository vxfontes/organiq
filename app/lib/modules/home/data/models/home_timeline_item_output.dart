import 'package:json_annotation/json_annotation.dart';

part 'home_timeline_item_output.g.dart';

@JsonSerializable()
class HomeTimelineItemOutput {
  const HomeTimelineItemOutput({
    required this.id,
    required this.itemType,
    required this.title,
    this.subtitle,
    required this.scheduledTime,
    this.endScheduledTime,
    required this.isCompleted,
    required this.isOverdue,
  });

  @JsonKey(fromJson: _stringFromJson, defaultValue: '')
  final String id;
  @JsonKey(name: 'item_type', fromJson: _itemTypeFromJson, defaultValue: '')
  final String itemType;
  @JsonKey(fromJson: _stringFromJson, defaultValue: '')
  final String title;
  @JsonKey(name: 'subtitle', fromJson: _subtitleFromJson)
  final String? subtitle;
  @JsonKey(name: 'scheduled_time', fromJson: _scheduledTimeFromJson)
  final DateTime scheduledTime;
  @JsonKey(name: 'end_scheduled_time', fromJson: _nullableDateTimeFromJson)
  final DateTime? endScheduledTime;
  @JsonKey(name: 'is_completed', fromJson: _boolFromJson, defaultValue: false)
  final bool isCompleted;
  @JsonKey(name: 'is_overdue', fromJson: _boolFromJson, defaultValue: false)
  final bool isOverdue;

  factory HomeTimelineItemOutput.fromJson(Map<String, dynamic> json) {
    return _$HomeTimelineItemOutputFromJson(json);
  }

  factory HomeTimelineItemOutput.fromDynamic(dynamic value) {
    try {
      return HomeTimelineItemOutput.fromJson(_asMap(value));
    } catch (_) {
      return HomeTimelineItemOutput(
        id: '',
        itemType: '',
        title: '',
        scheduledTime: DateTime.fromMillisecondsSinceEpoch(0),
        isCompleted: false,
        isOverdue: false,
      );
    }
  }

  HomeTimelineItemOutput copyWith({
    bool? isCompleted,
    bool? isOverdue,
    DateTime? scheduledTime,
    DateTime? endScheduledTime,
  }) {
    return HomeTimelineItemOutput(
      id: id,
      itemType: itemType,
      title: title,
      subtitle: subtitle,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      endScheduledTime: endScheduledTime ?? this.endScheduledTime,
      isCompleted: isCompleted ?? this.isCompleted,
      isOverdue: isOverdue ?? this.isOverdue,
    );
  }

  Map<String, dynamic> toJson() => _$HomeTimelineItemOutputToJson(this);

  static String _itemTypeFromJson(dynamic value) {
    if (value == null) return '';
    return value.toString().toLowerCase();
  }

  static String _stringFromJson(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static String? _subtitleFromJson(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return text;
  }

  static DateTime _scheduledTimeFromJson(dynamic value) {
    final parsed = _nullableDateTimeFromJson(value);
    return parsed ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _nullableDateTimeFromJson(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static bool _boolFromJson(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }
}
