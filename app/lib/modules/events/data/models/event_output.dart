import 'package:json_annotation/json_annotation.dart';
import 'package:organiq/modules/flags/data/models/flag_object_output.dart';

part 'event_output.g.dart';

@JsonSerializable()
class EventOutput {
  const EventOutput({
    required this.id,
    required this.title,
    this.startAt,
    this.endAt,
    this.allDay = false,
    this.location,
    this.flag,
    this.subflag,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool allDay;
  final String? location;
  final FlagObjectOutput? flag;
  final FlagObjectOutput? subflag;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String? get flagName => flag?.name;
  String? get subflagName => subflag?.name;
  String? get flagColor => flag?.color;
  String? get subflagColor => subflag?.color;

  factory EventOutput.fromJson(Map<String, dynamic> json) {
    return _$EventOutputFromJson(json);
  }

  factory EventOutput.fromDynamic(dynamic value) {
    return EventOutput.fromJson(_asMap(value));
  }

  Map<String, dynamic> toJson() => _$EventOutputToJson(this);

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}
