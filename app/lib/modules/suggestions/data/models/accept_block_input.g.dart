// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accept_block_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$AcceptBlockInputToJson(AcceptBlockInput instance) =>
    <String, dynamic>{
      'type': instance.type,
      'title': instance.title,
      'rationale': ?instance.rationale,
      'startsAt': ?instance.startsAt?.toIso8601String(),
      'endsAt': ?instance.endsAt?.toIso8601String(),
      'weekdays': instance.weekdays,
      'recurrenceType': ?instance.recurrenceType,
      'flagId': ?instance.flagId,
      'subflagId': ?instance.subflagId,
    };
