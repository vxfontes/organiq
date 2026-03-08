import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';
import 'package:inbota/modules/events/data/models/agenda_output.dart';
import 'package:inbota/modules/events/data/models/event_output.dart';
import 'package:inbota/modules/events/domain/usecases/get_agenda_usecase.dart';
import 'package:inbota/modules/reminders/data/models/reminder_output.dart';
import 'package:inbota/modules/routines/data/models/routine_list_output.dart';
import 'package:inbota/modules/routines/data/models/routine_output.dart';
import 'package:inbota/modules/routines/data/models/routine_today_summary_output.dart';
import 'package:inbota/modules/routines/domain/usecases/complete_routine_usecase.dart';
import 'package:inbota/modules/routines/domain/usecases/get_routines_by_weekday_usecase.dart';
import 'package:inbota/modules/routines/domain/usecases/get_today_summary_usecase.dart';
import 'package:inbota/modules/routines/domain/usecases/uncomplete_routine_usecase.dart';
import 'package:inbota/modules/shopping/data/models/shopping_item_output.dart';
import 'package:inbota/modules/shopping/data/models/shopping_list_list_output.dart';
import 'package:inbota/modules/shopping/data/models/shopping_list_output.dart';
import 'package:inbota/modules/shopping/domain/usecases/get_shopping_items_usecase.dart';
import 'package:inbota/modules/shopping/domain/usecases/get_shopping_lists_usecase.dart';
import 'package:inbota/modules/tasks/data/models/task_output.dart';
import 'package:inbota/modules/tasks/data/models/task_update_input.dart';
import 'package:inbota/modules/tasks/domain/usecases/update_task_usecase.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/state/ib_state.dart';

class HomeController implements IBController {
  HomeController(
    this._getAgendaUsecase,
    this._getShoppingListsUsecase,
    this._getShoppingItemsUsecase,
    this._updateTaskUsecase,
    this._getRoutinesByWeekdayUsecase,
    this._completeRoutineUsecase,
    this._uncompleteRoutineUsecase,
    this._getTodaySummaryUsecase,
  );

  final GetAgendaUsecase _getAgendaUsecase;
  final GetShoppingListsUsecase _getShoppingListsUsecase;
  final GetShoppingItemsUsecase _getShoppingItemsUsecase;
  final UpdateTaskUsecase _updateTaskUsecase;
  final GetRoutinesByWeekdayUsecase _getRoutinesByWeekdayUsecase;
  final CompleteRoutineUsecase _completeRoutineUsecase;
  final UncompleteRoutineUsecase _uncompleteRoutineUsecase;
  final GetTodaySummaryUsecase _getTodaySummaryUsecase;

  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<bool> refreshing = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);
  
  final ValueNotifier<AgendaOutput> agenda = ValueNotifier(
    const AgendaOutput(events: [], tasks: [], reminders: []),
  );
  final ValueNotifier<List<RoutineOutput>> routines = ValueNotifier([]);
  final ValueNotifier<RoutineTodaySummaryOutput?> routineSummary = ValueNotifier(null);
  
  final ValueNotifier<List<ShoppingListOutput>> shoppingLists = ValueNotifier(
    const [],
  );
  final ValueNotifier<Map<String, List<ShoppingItemOutput>>>
  shoppingItemsByList = ValueNotifier(const {});

  final Set<String> _updatingTaskIds = <String>{};
  final Set<String> _updatingRoutineIds = <String>{};

  bool get hasContent {
    return agenda.value.events.isNotEmpty ||
        agenda.value.tasks.isNotEmpty ||
        agenda.value.reminders.isNotEmpty ||
        shoppingLists.value.isNotEmpty ||
        routines.value.isNotEmpty;
  }

  List<TaskOutput> get openTasks {
    return agenda.value.tasks.where((item) => !item.isDone).toList();
  }

  List<TaskOutput> get overdueTasks {
    final now = DateTime.now();
    return openTasks
        .where(
          (item) => item.dueAt != null && item.dueAt!.toLocal().isBefore(now),
        )
        .toList();
  }

  List<TaskOutput> get criticalTasks {
    final now = DateTime.now();
    final list = List<TaskOutput>.from(openTasks);
    list.sort((a, b) {
      final aDue = a.dueAt?.toLocal();
      final bDue = b.dueAt?.toLocal();

      final aPriority = aDue == null ? 2 : (aDue.isBefore(now) ? 0 : 1);
      final bPriority = bDue == null ? 2 : (bDue.isBefore(now) ? 0 : 1);

      final byPriority = aPriority.compareTo(bPriority);
      if (byPriority != 0) return byPriority;

      if (aDue != null && bDue != null) {
        final byDate = aDue.compareTo(bDue);
        if (byDate != 0) return byDate;
      } else if (aDue != null) {
        return -1;
      } else if (bDue != null) {
        return 1;
      }

      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return list.take(5).toList(growable: false);
  }

  List<ReminderOutput> get openReminders {
    return agenda.value.reminders.where((item) => !item.isDone).toList();
  }

  List<ReminderOutput> get overdueReminders {
    final now = DateTime.now();
    return openReminders
        .where(
          (item) =>
              item.remindAt != null && item.remindAt!.toLocal().isBefore(now),
        )
        .toList();
  }

  List<ReminderOutput> get upcomingReminders {
    final now = DateTime.now();
    final list = openReminders
        .where(
          (item) =>
              item.remindAt != null && !item.remindAt!.toLocal().isBefore(now),
        )
        .toList();
    list.sort((a, b) {
      final aDate = a.remindAt?.toLocal();
      final bDate = b.remindAt?.toLocal();
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });
    return list;
  }

  List<EventOutput> get upcomingEvents {
    final now = DateTime.now();
    final list = eventsWithDate
        .where((item) => item.startAt != null)
        .toList(growable: false);

    final upcoming = list
        .where((item) => !item.startAt!.toLocal().isBefore(now))
        .toList();

    upcoming.sort(
      (a, b) => a.startAt!.toLocal().compareTo(b.startAt!.toLocal()),
    );
    return upcoming;
  }

  List<EventOutput> get homeUpcomingEventsPreview {
    return upcomingEvents.take(4).toList(growable: false);
  }

  List<ReminderOutput> get homeUpcomingRemindersPreview {
    return upcomingReminders.take(4).toList(growable: false);
  }

  List<EventOutput> get eventsWithDate {
    return agenda.value.events
        .where((item) => item.startAt != null)
        .toList(growable: false);
  }

  int get openTasksCount => openTasks.length;
  int get overdueTasksCount => overdueTasks.length;
  int get overdueRemindersCount => overdueReminders.length;
  int get totalOverdueCount => overdueTasksCount + overdueRemindersCount;

  int get remindersTodayCount {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return openReminders.where((item) {
      final date = item.remindAt?.toLocal();
      if (date == null) return false;
      return !date.isBefore(start) && date.isBefore(end);
    }).length;
  }

  int get remindersUpcomingCount {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    return openReminders.where((item) {
      final date = item.remindAt?.toLocal();
      if (date == null) return false;
      return !date.isBefore(start);
    }).length;
  }

  int get eventsTodayCount {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return eventsWithDate.where((item) {
      final date = item.startAt?.toLocal();
      if (date == null) return false;
      return !date.isBefore(start) && date.isBefore(end);
    }).length;
  }

  int get eventsThisWeekCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: today.weekday - 1));
    final end = start.add(const Duration(days: 7));
    return eventsWithDate.where((item) {
      final date = item.startAt?.toLocal();
      if (date == null) return false;
      return !date.isBefore(start) && date.isBefore(end);
    }).length;
  }

  List<ShoppingListOutput> get activeShoppingLists {
    return shoppingLists.value
        .where((list) => !list.isArchived)
        .toList(growable: false);
  }

  int get openShoppingListsCount {
    return activeShoppingLists.where((list) => !list.isDone).length;
  }

  int get pendingShoppingItemsCount {
    var total = 0;
    final byList = shoppingItemsByList.value;

    for (final list in activeShoppingLists) {
      if (list.isDone) continue;
      final items = byList[list.id] ?? const <ShoppingItemOutput>[];
      total += items.where((item) => !item.isDone).length;
    }

    return total;
  }

  int pendingItemsForList(String listId) {
    final items =
        shoppingItemsByList.value[listId] ?? const <ShoppingItemOutput>[];
    return items.where((item) => !item.isDone).length;
  }

  List<ShoppingListOutput> get homeShoppingListsPreview {
    final lists = activeShoppingLists.where((list) => !list.isDone).toList();
    lists.sort((a, b) {
      final byPending = pendingItemsForList(
        b.id,
      ).compareTo(pendingItemsForList(a.id));
      if (byPending != 0) return byPending;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return lists.take(3).toList(growable: false);
  }

  Future<void> load() async {
    await _fetch(initialLoad: true);
  }

  Future<void> refresh() async {
    await _fetch(initialLoad: false);
  }

  Future<void> toggleCriticalTaskAt(int index, bool done) async {
    final tasks = criticalTasks;
    if (index < 0 || index >= tasks.length) return;

    final task = tasks[index];
    if (_updatingTaskIds.contains(task.id)) return;

    _updatingTaskIds.add(task.id);
    final result = await _updateTaskUsecase.call(
      TaskUpdateInput(id: task.id, status: done ? 'DONE' : 'OPEN'),
    );
    _updatingTaskIds.remove(task.id);

    result.fold(
      (failure) {
        _setError(
          failure,
          fallback: 'Não foi possível atualizar a tarefa pela Home.',
        );
      },
      (updatedTask) {
        final current = agenda.value;
        final tasks = List<TaskOutput>.from(current.tasks);
        final taskIndex = tasks.indexWhere((item) => item.id == updatedTask.id);
        if (taskIndex == -1) return;

        tasks[taskIndex] = updatedTask;
        agenda.value = AgendaOutput(
          events: current.events,
          tasks: tasks,
          reminders: current.reminders,
        );
      },
    );
  }

  Future<void> toggleRoutine(RoutineOutput routine, bool completed) async {
    if (_updatingRoutineIds.contains(routine.id)) return;

    _updatingRoutineIds.add(routine.id);
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final result = completed 
      ? await _completeRoutineUsecase.call(routine.id, date: dateStr)
      : await _uncompleteRoutineUsecase.call(routine.id, dateStr);
    
    _updatingRoutineIds.remove(routine.id);

    result.fold(
      (failure) => _setError(failure, fallback: 'Não foi possível atualizar a rotina.'),
      (_) {
        final list = List<RoutineOutput>.from(routines.value);
        final idx = list.indexWhere((r) => r.id == routine.id);
        if (idx != -1) {
          list[idx] = list[idx].copyWith(isCompletedToday: completed);
          routines.value = list;
        }
        _refreshRoutineSummary();
      },
    );
  }

  Future<void> _refreshRoutineSummary() async {
    final result = await _getTodaySummaryUsecase.call();
    result.fold((_) => null, (summary) => routineSummary.value = summary);
  }

  Future<void> _fetch({required bool initialLoad}) async {
    if (loading.value || refreshing.value) return;

    if (initialLoad) {
      loading.value = true;
    } else {
      refreshing.value = true;
    }
    error.value = null;

    final agendaFuture = _getAgendaUsecase.call(limit: 200);
    final listsFuture = _getShoppingListsUsecase.call(limit: 20);
    
    final now = DateTime.now();
    final weekday = now.weekday % 7;
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final routinesFuture = _getRoutinesByWeekdayUsecase.call(weekday, date: dateStr);
    final summaryFuture = _getTodaySummaryUsecase.call();

    final results = await Future.wait([
      agendaFuture,
      listsFuture,
      routinesFuture,
      summaryFuture,
    ]);

    final agendaResult = results[0] as Either<Failure, AgendaOutput>;
    final listsResult = results[1] as Either<Failure, ShoppingListListOutput>;
    final routinesResult = results[2] as Either<Failure, RoutineListOutput>;
    final summaryResult = results[3] as Either<Failure, RoutineTodaySummaryOutput>;

    agendaResult.fold(
      (failure) =>
          _setError(failure, fallback: 'Não foi possível carregar agenda.'),
      (output) => agenda.value = output,
    );

    summaryResult.fold((_) => null, (summary) => routineSummary.value = summary);

    routinesResult.fold(
      (failure) => _setError(failure, fallback: 'Não foi possível carregar rotinas.'),
      (data) {
        routines.value = data.items;
      },
    );

    final lists = listsResult.fold<List<ShoppingListOutput>>(
      (failure) {
        _setError(
          failure,
          fallback: 'Não foi possível carregar listas de compras.',
        );
        return const [];
      },
      (output) => output.items
          .where((list) => !list.isArchived)
          .toList(growable: false),
    );
    shoppingLists.value = lists;

    final nextItemsByList = <String, List<ShoppingItemOutput>>{};
    final itemsResults = await Future.wait(
      lists.map((list) async {
        final result = await _getShoppingItemsUsecase.call(
          listId: list.id,
          limit: 200,
        );
        return MapEntry(list.id, result);
      }),
    );

    for (final entry in itemsResults) {
      entry.value.fold(
        (failure) {
          _setError(
            failure,
            fallback: 'Não foi possível carregar itens de compras da Home.',
          );
          nextItemsByList[entry.key] = const [];
        },
        (output) {
          nextItemsByList[entry.key] = output.items;
        },
      );
    }
    shoppingItemsByList.value = nextItemsByList;

    loading.value = false;
    refreshing.value = false;
  }

  void _setError(Failure failure, {required String fallback}) {
    final message = failure.message?.trim();
    if (message != null && message.isNotEmpty) {
      error.value = message;
      return;
    }

    if (error.value == null || error.value!.isEmpty) {
      error.value = fallback;
    }
  }

  @override
  void dispose() {
    loading.dispose();
    refreshing.dispose();
    error.dispose();
    agenda.dispose();
    routines.dispose();
    routineSummary.dispose();
    shoppingLists.dispose();
    shoppingItemsByList.dispose();
  }
}
