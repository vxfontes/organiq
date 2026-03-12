import 'package:inbota/modules/inbox/data/models/inbox_create_line_result.dart';

class LineProcessSuccess {
  const LineProcessSuccess({
    required this.lineResults,
    this.tasksCount = 0,
    this.remindersCount = 0,
    this.eventsCount = 0,
    this.routinesCount = 0,
    this.shoppingListsCount = 0,
    this.shoppingItemsCount = 0,
  });

  final List<CreateLineResult> lineResults;
  final int tasksCount;
  final int remindersCount;
  final int eventsCount;
  final int routinesCount;
  final int shoppingListsCount;
  final int shoppingItemsCount;
}