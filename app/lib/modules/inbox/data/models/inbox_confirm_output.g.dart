// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inbox_confirm_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InboxConfirmOutput _$InboxConfirmOutputFromJson(Map<String, dynamic> json) =>
    InboxConfirmOutput(
      type: json['type'] as String,
      task: json['task'] == null
          ? null
          : TaskOutput.fromJson(json['task'] as Map<String, dynamic>),
      reminder: json['reminder'] == null
          ? null
          : ReminderOutput.fromJson(json['reminder'] as Map<String, dynamic>),
      event: json['event'] == null
          ? null
          : EventOutput.fromJson(json['event'] as Map<String, dynamic>),
      routine: json['routine'] == null
          ? null
          : RoutineOutput.fromJson(json['routine'] as Map<String, dynamic>),
      shoppingList: json['shoppingList'] == null
          ? null
          : ShoppingListOutput.fromJson(
              json['shoppingList'] as Map<String, dynamic>,
            ),
      shoppingItems:
          (json['shoppingItems'] as List<dynamic>?)
              ?.map(
                (e) => ShoppingItemOutput.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <ShoppingItemOutput>[],
    );

Map<String, dynamic> _$InboxConfirmOutputToJson(InboxConfirmOutput instance) =>
    <String, dynamic>{
      'type': instance.type,
      'task': instance.task,
      'reminder': instance.reminder,
      'event': instance.event,
      'routine': instance.routine,
      'shoppingList': instance.shoppingList,
      'shoppingItems': instance.shoppingItems,
    };
