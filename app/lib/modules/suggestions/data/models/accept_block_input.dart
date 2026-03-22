import 'package:organiq/modules/suggestions/data/models/suggestion_block.dart';
import 'package:json_annotation/json_annotation.dart';

part 'accept_block_input.g.dart';

String? _dateToUtcIso(DateTime? value) => value?.toUtc().toIso8601String();

@JsonSerializable(includeIfNull: false, createFactory: false)
class AcceptBlockInput {
  const AcceptBlockInput({
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

  final String type;
  final String title;
  final String? rationale;
  @JsonKey(toJson: _dateToUtcIso)
  final DateTime? startsAt;
  @JsonKey(toJson: _dateToUtcIso)
  final DateTime? endsAt;
  final List<int> weekdays;
  final String? recurrenceType;
  final String? flagId;
  final String? subflagId;

  factory AcceptBlockInput.fromBlock(SuggestionBlock block) {
    final normalizedStartsAt = (block.startsAt ?? block.endsAt)?.toLocal();
    final normalizedEndsAt = block.startsAt == null ? null : block.endsAt?.toLocal();
    final normalizedType = normalizedStartsAt != null ? 'event' : block.type;

    return AcceptBlockInput(
      type: normalizedType,
      title: block.title,
      rationale: block.rationale,
      startsAt: normalizedStartsAt,
      endsAt: normalizedEndsAt,
      weekdays: block.weekdays,
      recurrenceType: block.recurrenceType,
      flagId: block.flagId,
      subflagId: block.subflagId,
    );
  }

  Map<String, dynamic> toJson() => _$AcceptBlockInputToJson(this);
}
