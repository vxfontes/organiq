import 'package:organiq/modules/suggestions/data/models/suggestion_block.dart';
import 'package:json_annotation/json_annotation.dart';

part 'suggestion_message_output.g.dart';

@JsonSerializable()
class SuggestionMessageOutput {
  const SuggestionMessageOutput({
    required this.conversationId,
    required this.messageId,
    required this.text,
    this.blocks = const <SuggestionBlock>[],
  });

  final String conversationId;
  final String messageId;
  final String text;
  final List<SuggestionBlock> blocks;

  factory SuggestionMessageOutput.fromJson(Map<String, dynamic> json) =>
      _$SuggestionMessageOutputFromJson(json);

  factory SuggestionMessageOutput.fromDynamic(dynamic value) {
    return SuggestionMessageOutput.fromJson(_asMap(value));
  }

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  Map<String, dynamic> toJson() => _$SuggestionMessageOutputToJson(this);
}
