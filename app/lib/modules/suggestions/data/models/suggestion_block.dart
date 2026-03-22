import 'package:json_annotation/json_annotation.dart';

part 'suggestion_block.g.dart';

@JsonSerializable(includeIfNull: false)
class SuggestionBlock {
  const SuggestionBlock({
    required this.id,
    required this.type,
    required this.title,
    this.rationale,
    this.startsAt,
    this.endsAt,
    this.weekdays = const <int>[],
    this.recurrenceType,
    this.flagId,
    this.subflagId,
  });

  final String id;
  final String type;
  final String title;
  final String? rationale;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final List<int> weekdays;
  final String? recurrenceType;
  final String? flagId;
  final String? subflagId;

  bool get isTask => type.toLowerCase() == 'task';
  bool get isEvent => type.toLowerCase() == 'event';
  bool get isRoutine => type.toLowerCase() == 'routine';

  factory SuggestionBlock.fromJson(Map<String, dynamic> json) =>
      _$SuggestionBlockFromJson(json);

  factory SuggestionBlock.fromDynamic(dynamic value) {
    return SuggestionBlock.fromJson(_asMap(value));
  }

  Map<String, dynamic> toJson() => _$SuggestionBlockToJson(this);

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}
