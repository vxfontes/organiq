// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suggestion_message_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SuggestionMessageOutput _$SuggestionMessageOutputFromJson(
  Map<String, dynamic> json,
) => SuggestionMessageOutput(
  conversationId: json['conversationId'] as String,
  messageId: json['messageId'] as String,
  text: json['text'] as String,
  blocks:
      (json['blocks'] as List<dynamic>?)
          ?.map((e) => SuggestionBlock.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SuggestionBlock>[],
);

Map<String, dynamic> _$SuggestionMessageOutputToJson(
  SuggestionMessageOutput instance,
) => <String, dynamic>{
  'conversationId': instance.conversationId,
  'messageId': instance.messageId,
  'text': instance.text,
  'blocks': instance.blocks,
};
