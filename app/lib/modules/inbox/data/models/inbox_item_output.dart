import 'package:json_annotation/json_annotation.dart';

import 'inbox_confirm_output.dart';
import 'inbox_suggestion_output.dart';

part 'inbox_item_output.g.dart';

@JsonSerializable()
class InboxItemOutput {
  const InboxItemOutput({
    required this.id,
    required this.source,
    required this.rawText,
    this.rawMediaUrl,
    required this.status,
    this.lastError,
    this.createdAt,
    this.updatedAt,
    this.suggestion,
    this.suggestions = const <InboxSuggestionOutput>[],
    this.confirmed = const <InboxConfirmOutput>[],
  });

  final String id;
  final String source;
  final String rawText;
  final String? rawMediaUrl;
  final String status;
  final String? lastError;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final InboxSuggestionOutput? suggestion;
  final List<InboxSuggestionOutput> suggestions;
  final List<InboxConfirmOutput> confirmed;

  factory InboxItemOutput.fromJson(Map<String, dynamic> json) {
    return _$InboxItemOutputFromJson(json);
  }

  factory InboxItemOutput.fromDynamic(dynamic value) {
    return InboxItemOutput.fromJson(_asMap(value));
  }

  Map<String, dynamic> toJson() => _$InboxItemOutputToJson(this);

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}
