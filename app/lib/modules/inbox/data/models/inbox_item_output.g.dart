// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inbox_item_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InboxItemOutput _$InboxItemOutputFromJson(Map<String, dynamic> json) =>
    InboxItemOutput(
      id: json['id'] as String,
      source: json['source'] as String,
      rawText: json['rawText'] as String,
      rawMediaUrl: json['rawMediaUrl'] as String?,
      status: json['status'] as String,
      lastError: json['lastError'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      suggestion: json['suggestion'] == null
          ? null
          : InboxSuggestionOutput.fromJson(
              json['suggestion'] as Map<String, dynamic>,
            ),
      suggestions:
          (json['suggestions'] as List<dynamic>?)
              ?.map(
                (e) =>
                    InboxSuggestionOutput.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <InboxSuggestionOutput>[],
      confirmed:
          (json['confirmed'] as List<dynamic>?)
              ?.map(
                (e) => InboxConfirmOutput.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <InboxConfirmOutput>[],
    );

Map<String, dynamic> _$InboxItemOutputToJson(InboxItemOutput instance) =>
    <String, dynamic>{
      'id': instance.id,
      'source': instance.source,
      'rawText': instance.rawText,
      'rawMediaUrl': instance.rawMediaUrl,
      'status': instance.status,
      'lastError': instance.lastError,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'suggestion': instance.suggestion,
      'suggestions': instance.suggestions,
      'confirmed': instance.confirmed,
    };
