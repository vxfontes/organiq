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
      'startsAt': ?_dateToUtcIso(instance.startsAt),
      'endsAt': ?_dateToUtcIso(instance.endsAt),
      'weekdays': instance.weekdays,
      'recurrenceType': ?instance.recurrenceType,
      'flagId': ?instance.flagId,
      'subflagId': ?instance.subflagId,
    };
