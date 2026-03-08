// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoutineOutput _$RoutineOutputFromJson(Map<String, dynamic> json) =>
    RoutineOutput(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      recurrenceType: json['recurrenceType'] as String,
      weekdays: (json['weekdays'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String?,
      weekOfMonth: (json['weekOfMonth'] as num?)?.toInt(),
      startsOn: json['startsOn'] as String,
      endsOn: json['endsOn'] as String?,
      color: json['color'] as String?,
      isActive: json['isActive'] as bool,
      isCompletedToday: json['isCompletedToday'] as bool? ?? false,
      flag: json['flag'] == null
          ? null
          : FlagObjectOutput.fromJson(json['flag'] as Map<String, dynamic>),
      subflag: json['subflag'] == null
          ? null
          : FlagObjectOutput.fromJson(json['subflag'] as Map<String, dynamic>),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$RoutineOutputToJson(RoutineOutput instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'recurrenceType': instance.recurrenceType,
      'weekdays': instance.weekdays,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'weekOfMonth': instance.weekOfMonth,
      'startsOn': instance.startsOn,
      'endsOn': instance.endsOn,
      'color': instance.color,
      'isActive': instance.isActive,
      'isCompletedToday': instance.isCompletedToday,
      'flag': instance.flag,
      'subflag': instance.subflag,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
