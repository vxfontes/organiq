// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suggestion_conversation_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SuggestionConversationOutput _$SuggestionConversationOutputFromJson(
  Map<String, dynamic> json,
) => SuggestionConversationOutput(
  id: json['id'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  messages:
      (json['messages'] as List<dynamic>?)
          ?.map(
            (e) => SuggestionConversationMessageOutput.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList() ??
      const <SuggestionConversationMessageOutput>[],
);

Map<String, dynamic> _$SuggestionConversationOutputToJson(
  SuggestionConversationOutput instance,
) => <String, dynamic>{
  'id': instance.id,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'messages': instance.messages,
};

SuggestionConversationMessageOutput
_$SuggestionConversationMessageOutputFromJson(Map<String, dynamic> json) =>
    SuggestionConversationMessageOutput(
      id: json['id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      blocks:
          (json['blocks'] as List<dynamic>?)
              ?.map((e) => SuggestionBlock.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <SuggestionBlock>[],
    );

Map<String, dynamic> _$SuggestionConversationMessageOutputToJson(
  SuggestionConversationMessageOutput instance,
) => <String, dynamic>{
  'id': instance.id,
  'role': instance.role,
  'content': instance.content,
  'createdAt': instance.createdAt.toIso8601String(),
  'blocks': instance.blocks,
};
