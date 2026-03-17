import 'package:json_annotation/json_annotation.dart';
import 'package:organiq/modules/inbox/data/models/inbox_item_output.dart';

part 'inbox_confirm_input.g.dart';

@JsonSerializable(includeIfNull: false, createFactory: false)
class InboxConfirmInput {
  const InboxConfirmInput({
    required this.id,
    required this.type,
    required this.title,
    required this.payload,
    this.flagId,
    this.subflagId,
  });

  @JsonKey(includeFromJson: false, includeToJson: false)
  final String id;

  final String type;
  final String title;
  final dynamic payload;
  final String? flagId;
  final String? subflagId;

  factory InboxConfirmInput.fromSuggestion(
    InboxItemOutput item, {
    String? fallbackTitle,
  }) {
    final suggestion = item.suggestion;
    final normalizedType = suggestion?.type.trim().toLowerCase() ?? '';
    return InboxConfirmInput(
      id: item.id,
      type: normalizedType,
      title: (suggestion?.title.trim().isNotEmpty ?? false)
          ? suggestion!.title.trim()
          : (fallbackTitle?.trim().isNotEmpty ?? false)
          ? fallbackTitle!.trim()
          : item.rawText.trim(),
      payload: suggestion?.payload,
      flagId: suggestion?.flag?.id,
      subflagId: suggestion?.subflag?.id,
    );
  }

  bool get isValidForConfirm {
    return id.trim().isNotEmpty &&
        type.trim().isNotEmpty &&
        title.trim().isNotEmpty &&
        payload != null;
  }

  Map<String, dynamic> toJson() => _$InboxConfirmInputToJson(this);
}
