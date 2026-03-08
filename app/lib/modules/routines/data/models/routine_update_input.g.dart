// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_update_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoutineUpdateInput _$RoutineUpdateInputFromJson(Map<String, dynamic> json) =>
    RoutineUpdateInput(
      title: json['title'] as String?,
      description: json['description'] as String?,
      recurrenceType: json['recurrenceType'] as String?,
      weekdays: (json['weekdays'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      weekOfMonth: (json['weekOfMonth'] as num?)?.toInt(),
      startsOn: json['startsOn'] as String?,
      endsOn: json['endsOn'] as String?,
      color: json['color'] as String?,
      flagId: json['flagId'] as String?,
      subflagId: json['subflagId'] as String?,
    );

Map<String, dynamic> _$RoutineUpdateInputToJson(RoutineUpdateInput instance) =>
    <String, dynamic>{
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
      'flagId': instance.flagId,
      'subflagId': instance.subflagId,
    };
