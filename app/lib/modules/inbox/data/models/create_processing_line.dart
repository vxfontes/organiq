import 'package:organiq/modules/inbox/data/models/inbox_suggestion_output.dart';

enum LineProcessingStatus { pending, processing, done, failed }

class CreateProcessingLine {
  const CreateProcessingLine({
    required this.text,
    required this.status,
    this.message,
    this.suggestions,
    this.inboxItemId,
  });

  final String text;
  final LineProcessingStatus status;
  final String? message;
  final List<InboxSuggestionOutput>? suggestions;
  final String? inboxItemId;

  CreateProcessingLine copyWith({
    LineProcessingStatus? status,
    String? message,
    List<InboxSuggestionOutput>? suggestions,
    String? inboxItemId,
  }) {
    return CreateProcessingLine(
      text: text,
      status: status ?? this.status,
      message: message ?? this.message,
      suggestions: suggestions ?? this.suggestions,
      inboxItemId: inboxItemId ?? this.inboxItemId,
    );
  }
}
