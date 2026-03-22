import 'package:organiq/modules/suggestions/data/models/suggestion_block.dart';
import 'package:json_annotation/json_annotation.dart';

part 'accept_block_input.g.dart';

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
  final DateTime? startsAt;
  final DateTime? endsAt;
  final List<int> weekdays;
  final String? recurrenceType;
  final String? flagId;
  final String? subflagId;

  factory AcceptBlockInput.fromBlock(SuggestionBlock block) {
    return AcceptBlockInput(
      type: block.type,
      title: block.title,
      rationale: block.rationale,
      startsAt: block.startsAt,
      endsAt: block.endsAt,
      weekdays: block.weekdays,
      recurrenceType: block.recurrenceType,
      flagId: block.flagId,
      subflagId: block.subflagId,
    );
  }

  Map<String, dynamic> toJson() => _$AcceptBlockInputToJson(this);
}
