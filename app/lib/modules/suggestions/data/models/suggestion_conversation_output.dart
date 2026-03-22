import 'package:organiq/modules/suggestions/data/models/suggestion_block.dart';
import 'package:json_annotation/json_annotation.dart';

part 'suggestion_conversation_output.g.dart';

@JsonSerializable()
class SuggestionConversationOutput {
  const SuggestionConversationOutput({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    this.messages = const <SuggestionConversationMessageOutput>[],
  });

  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<SuggestionConversationMessageOutput> messages;

  factory SuggestionConversationOutput.fromJson(Map<String, dynamic> json) =>
      _$SuggestionConversationOutputFromJson(json);

  factory SuggestionConversationOutput.fromDynamic(dynamic value) {
    return SuggestionConversationOutput.fromJson(_asMap(value));
  }

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  Map<String, dynamic> toJson() => _$SuggestionConversationOutputToJson(this);
}

@JsonSerializable()
class SuggestionConversationMessageOutput {
  const SuggestionConversationMessageOutput({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.blocks = const <SuggestionBlock>[],
  });

  final String id;
  final String role;
  final String content;
  final DateTime createdAt;
  final List<SuggestionBlock> blocks;

  bool get isUser => role.toLowerCase() == 'user';

  factory SuggestionConversationMessageOutput.fromJson(
    Map<String, dynamic> json,
  ) => _$SuggestionConversationMessageOutputFromJson(json);

  factory SuggestionConversationMessageOutput.fromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) {
      return SuggestionConversationMessageOutput.fromJson(value);
    }
    if (value is Map) {
      return SuggestionConversationMessageOutput.fromJson(
        value.map((key, val) => MapEntry(key.toString(), val)),
      );
    }
    return SuggestionConversationMessageOutput(
      id: '',
      role: 'assistant',
      content: '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  SuggestionConversationMessageOutput copyWith({
    String? id,
    String? role,
    String? content,
    DateTime? createdAt,
    List<SuggestionBlock>? blocks,
  }) {
    return SuggestionConversationMessageOutput(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      blocks: blocks ?? this.blocks,
    );
  }

  Map<String, dynamic> toJson() =>
      _$SuggestionConversationMessageOutputToJson(this);
}
