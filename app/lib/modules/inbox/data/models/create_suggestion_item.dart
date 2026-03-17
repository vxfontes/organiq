import 'package:organiq/modules/inbox/data/models/inbox_confirm_input.dart';
import 'package:organiq/modules/inbox/data/models/inbox_suggestion_output.dart';

class CreateSuggestionItem {
  const CreateSuggestionItem({
    required this.sourceText,
    required this.inboxItemId,
    required this.suggestion,
    this.removed = false,
    this.editedTitle,
    this.editedType,
    this.editedPayload,
    this.editedFlagId,
    this.editedSubflagId,
  });

  final String sourceText;
  final String inboxItemId;
  final InboxSuggestionOutput suggestion;
  final bool removed;
  final String? editedTitle;
  final String? editedType;
  final dynamic editedPayload;
  final String? editedFlagId;
  final String? editedSubflagId;

  String get resolvedTitle => editedTitle ?? suggestion.title;
  String get resolvedType => editedType ?? suggestion.type;
  dynamic get resolvedPayload => editedPayload ?? suggestion.payload;
  String? get resolvedFlagId => editedFlagId ?? suggestion.flag?.id;
  String? get resolvedSubflagId => editedSubflagId ?? suggestion.subflag?.id;

  CreateSuggestionItem copyWith({
    bool? removed,
    String? editedTitle,
    String? editedType,
    dynamic editedPayload,
    String? editedFlagId,
    String? editedSubflagId,
  }) {
    return CreateSuggestionItem(
      sourceText: sourceText,
      inboxItemId: inboxItemId,
      suggestion: suggestion,
      removed: removed ?? this.removed,
      editedTitle: editedTitle ?? this.editedTitle,
      editedType: editedType ?? this.editedType,
      editedPayload: editedPayload ?? this.editedPayload,
      editedFlagId: editedFlagId ?? this.editedFlagId,
      editedSubflagId: editedSubflagId ?? this.editedSubflagId,
    );
  }

  InboxConfirmInput toConfirmInput() {
    return InboxConfirmInput(
      id: inboxItemId,
      type: resolvedType.trim().toLowerCase(),
      title: resolvedTitle.trim(),
      payload: resolvedPayload,
      flagId: resolvedFlagId,
      subflagId: resolvedSubflagId,
    );
  }
}
