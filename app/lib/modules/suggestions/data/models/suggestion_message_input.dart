import 'package:json_annotation/json_annotation.dart';

part 'suggestion_message_input.g.dart';

@JsonSerializable(includeIfNull: false, createFactory: false)
class SuggestionMessageInput {
  const SuggestionMessageInput({this.conversationId, required this.message});

  final String? conversationId;
  final String message;

  Map<String, dynamic> toJson() => _$SuggestionMessageInputToJson(this);
}
