import 'package:json_annotation/json_annotation.dart';
import 'package:inbota/modules/events/data/models/event_output.dart';
import 'package:inbota/modules/reminders/data/models/reminder_output.dart';
import 'package:inbota/modules/routines/data/models/routine_output.dart';
import 'package:inbota/modules/shopping/data/models/shopping_item_output.dart';
import 'package:inbota/modules/shopping/data/models/shopping_list_output.dart';
import 'package:inbota/modules/tasks/data/models/task_output.dart';

part 'inbox_confirm_output.g.dart';

@JsonSerializable(createToJson: false)
class InboxConfirmOutput {
  const InboxConfirmOutput({
    required this.type,
    this.task,
    this.reminder,
    this.event,
    this.routine,
    this.shoppingList,
    this.shoppingItems = const <ShoppingItemOutput>[],
  });

  final String type;
  final TaskOutput? task;
  final ReminderOutput? reminder;
  final EventOutput? event;
  final RoutineOutput? routine;
  final ShoppingListOutput? shoppingList;
  final List<ShoppingItemOutput> shoppingItems;

  factory InboxConfirmOutput.fromJson(Map<String, dynamic> json) {
    return _$InboxConfirmOutputFromJson(json);
  }

  factory InboxConfirmOutput.fromDynamic(dynamic value) {
    return InboxConfirmOutput.fromJson(_asMap(value));
  }

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}
