import 'package:inbota/modules/inbox/data/models/inbox_create_line_result.dart';

class CreateBatchResult {
  const CreateBatchResult({
    required this.totalInputs,
    required this.successCount,
    required this.failedCount,
    required this.tasksCount,
    required this.remindersCount,
    required this.eventsCount,
    required this.shoppingListsCount,
    required this.shoppingItemsCount,
    required this.routinesCount,
    required this.lines,
  });

  final int totalInputs;
  final int successCount;
  final int failedCount;
  final int tasksCount;
  final int remindersCount;
  final int eventsCount;
  final int shoppingListsCount;
  final int shoppingItemsCount;
  final int routinesCount;
  final List<CreateLineResult> lines;
}
