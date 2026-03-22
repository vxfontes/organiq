// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suggestion_block.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SuggestionBlock _$SuggestionBlockFromJson(Map<String, dynamic> json) =>
    SuggestionBlock(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      rationale: json['rationale'] as String?,
      startsAt: json['startsAt'] == null
          ? null
          : DateTime.parse(json['startsAt'] as String),
      endsAt: json['endsAt'] == null
          ? null
          : DateTime.parse(json['endsAt'] as String),
      weekdays:
          (json['weekdays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      recurrenceType: json['recurrenceType'] as String?,
      flagId: json['flagId'] as String?,
      subflagId: json['subflagId'] as String?,
    );

Map<String, dynamic> _$SuggestionBlockToJson(SuggestionBlock instance) =>
    <String, dynamic>{
      'id': instance.id,
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
