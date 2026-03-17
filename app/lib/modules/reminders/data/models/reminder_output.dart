import 'package:json_annotation/json_annotation.dart';
import 'package:organiq/modules/flags/data/models/flag_object_output.dart';

part 'reminder_output.g.dart';

@JsonSerializable()
class ReminderOutput {
  const ReminderOutput({
    required this.id,
    required this.title,
    required this.status,
    this.remindAt,
    this.flag,
    this.subflag,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String status;
  final DateTime? remindAt;
  final FlagObjectOutput? flag;
  final FlagObjectOutput? subflag;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String? get flagName => flag?.name;
  String? get subflagName => subflag?.name;
  String? get flagColor => flag?.color;
  String? get subflagColor => subflag?.color;

  bool get isDone => status.toUpperCase() == 'DONE';

  factory ReminderOutput.fromJson(Map<String, dynamic> json) {
    return _$ReminderOutputFromJson(json);
  }

  factory ReminderOutput.fromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) return ReminderOutput.fromJson(value);
    if (value is Map) {
      return ReminderOutput.fromJson(
        value.map((key, val) => MapEntry(key.toString(), val)),
      );
    }
    return const ReminderOutput(id: '', title: '', status: 'OPEN');
  }

  ReminderOutput copyWith({String? status}) {
    return ReminderOutput(
      id: id,
      title: title,
      status: status ?? this.status,
      remindAt: remindAt,
      flag: flag,
      subflag: subflag,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() => _$ReminderOutputToJson(this);
}
