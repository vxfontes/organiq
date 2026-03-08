// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_list_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoutineListOutput _$RoutineListOutputFromJson(Map<String, dynamic> json) =>
    RoutineListOutput(
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => RoutineOutput.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      nextCursor: json['nextCursor'] as String?,
    );

Map<String, dynamic> _$RoutineListOutputToJson(RoutineListOutput instance) =>
    <String, dynamic>{
      'items': instance.items,
      'nextCursor': instance.nextCursor,
    };
