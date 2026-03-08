import 'package:json_annotation/json_annotation.dart';
import 'package:inbota/modules/flags/data/models/flag_object_output.dart';

part 'routine_output.g.dart';

@JsonSerializable()
class RoutineOutput {
  const RoutineOutput({
    required this.id,
    required this.title,
    this.description,
    required this.recurrenceType,
    required this.weekdays,
    required this.startTime,
    this.endTime,
    this.weekOfMonth,
    required this.startsOn,
    this.endsOn,
    this.color,
    required this.isActive,
    this.isCompletedToday = false,
    this.flag,
    this.subflag,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final String recurrenceType;
  final List<int> weekdays;
  final String startTime;
  final String? endTime;
  final int? weekOfMonth;
  final String startsOn;
  final String? endsOn;
  final String? color;
  final bool isActive;
  final bool isCompletedToday;
  final FlagObjectOutput? flag;
  final FlagObjectOutput? subflag;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String? get flagName => flag?.name;
  String? get subflagName => subflag?.name;
  String? get flagColor => flag?.color;
  String? get subflagColor => subflag?.color;

  String get recurrenceTypeLabel {
    switch (recurrenceType) {
      case 'weekly':
        return 'Semanal';
      case 'biweekly':
        return 'Quinzenal';
      case 'triweekly':
        return '3 em 3 semanas';
      case 'monthly_week':
        return 'Mensal';
      default:
        return recurrenceType;
    }
  }

  String get weekdaysLabel {
    if (weekdays.length == 7) return 'Todo dia';
    if (weekdays.length == 5 &&
        weekdays.contains(1) &&
        weekdays.contains(2) &&
        weekdays.contains(3) &&
        weekdays.contains(4) &&
        weekdays.contains(5)) {
      return 'Seg-Sex';
    }
    if (weekdays.length == 2 && weekdays.contains(0) && weekdays.contains(6)) {
      return 'Final de semana';
    }

    const dayNames = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    final sorted = List<int>.from(weekdays)..sort();
    return sorted.map((d) => dayNames[d]).join('-');
  }

  String get timeLabel {
    final start = _formatTime(startTime);
    final end = _formatTime(endTime ?? '');
    if (end.isNotEmpty) {
      return '$start - $end';
    }
    return start;
  }

  String _formatTime(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    final match = RegExp(r'(\d{1,2}):(\d{1,2})').firstMatch(value);
    if (match == null) return value;
    final hour = match.group(1)!.padLeft(2, '0');
    final minute = match.group(2)!.padLeft(2, '0');
    return '$hour:$minute';
  }

  factory RoutineOutput.fromJson(Map<String, dynamic> json) {
    return _$RoutineOutputFromJson(json);
  }

  factory RoutineOutput.fromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) return RoutineOutput.fromJson(value);
    if (value is Map) {
      return RoutineOutput.fromJson(
        value.map((key, val) => MapEntry(key.toString(), val)),
      );
    }
    return const RoutineOutput(
      id: '',
      title: '',
      recurrenceType: 'weekly',
      weekdays: [],
      startTime: '',
      startsOn: '',
      isActive: true,
    );
  }

  RoutineOutput copyWith({
    String? id,
    String? title,
    String? description,
    String? recurrenceType,
    List<int>? weekdays,
    String? startTime,
    String? endTime,
    int? weekOfMonth,
    String? startsOn,
    String? endsOn,
    String? color,
    bool? isActive,
    bool? isCompletedToday,
    FlagObjectOutput? flag,
    FlagObjectOutput? subflag,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoutineOutput(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      weekdays: weekdays ?? this.weekdays,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      weekOfMonth: weekOfMonth ?? this.weekOfMonth,
      startsOn: startsOn ?? this.startsOn,
      endsOn: endsOn ?? this.endsOn,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
      flag: flag ?? this.flag,
      subflag: subflag ?? this.subflag,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => _$RoutineOutputToJson(this);
}
