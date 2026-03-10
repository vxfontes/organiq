import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:inbota/modules/events/data/models/agenda_output.dart';
import 'package:inbota/modules/events/data/models/event_output.dart';
import 'package:inbota/modules/events/domain/usecases/get_agenda_usecase.dart';
import 'package:inbota/modules/reminders/data/models/reminder_output.dart';
import 'package:inbota/modules/reminders/data/models/reminder_update_input.dart';
import 'package:inbota/modules/reminders/domain/usecases/update_reminder_usecase.dart';
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
import 'package:inbota/presentation/screens/home_module/components/timeline_item.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/state/ib_state.dart';
import 'package:inbota/shared/utils/text_utils.dart';

class HomeController implements IBController {
  HomeController(
    this._getAgendaUsecase,
    this._getShoppingListsUsecase,
    this._getShoppingItemsUsecase,
    this._updateTaskUsecase,
    this._updateReminderUsecase,
    this._getRoutinesByWeekdayUsecase,
    this._completeRoutineUsecase,
    this._uncompleteRoutineUsecase,
    this._getTodaySummaryUsecase,
  );

  final GetAgendaUsecase _getAgendaUsecase;
  final GetShoppingListsUsecase _getShoppingListsUsecase;
  final GetShoppingItemsUsecase _getShoppingItemsUsecase;
  final UpdateTaskUsecase _updateTaskUsecase;
  final UpdateReminderUsecase _updateReminderUsecase;
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
  final ValueNotifier<RoutineTodaySummaryOutput?> routineSummary =
      ValueNotifier(null);

  final ValueNotifier<List<ShoppingListOutput>> shoppingLists = ValueNotifier(
    const [],
  );
  final ValueNotifier<Map<String, List<ShoppingItemOutput>>>
  shoppingItemsByList = ValueNotifier(const {});

  final Set<String> _updatingTaskIds = <String>{};
  final Set<String> _updatingReminderIds = <String>{};
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

  List<TaskOutput> get criticalTasks => focusTasks;

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

  int get openShoppingLists => openShoppingListsCount;

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

  int get totalPendingShoppingItems => pendingShoppingItemsCount;

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

  List<TimelineItem> get nextActionsTimeline {
    final now = DateTime.now();
    return _timelineItemsToday
        .where((item) => !item.scheduledTime.isBefore(now))
        .take(10)
        .toList(growable: false);
  }

  List<TimelineItem> get pastActionsToday {
    final now = DateTime.now();
    return _timelineItemsToday
        .where((item) => item.scheduledTime.isBefore(now))
        .toList(growable: false);
  }

  int get routinesDone {
    final summary = routineSummary.value;
    if (summary != null) return summary.completed;
    return routines.value.where((item) => item.isCompletedToday).length;
  }

  int get routinesTotal {
    final summary = routineSummary.value;
    if (summary != null) return summary.total;
    return routines.value.length;
  }

  int get tasksDone {
    return _todayTasksForProgress.where((item) => item.isDone).length;
  }

  int get tasksTotal {
    return _todayTasksForProgress.length;
  }

  int get remindersDone {
    return _todayRemindersForProgress.where((item) => item.isDone).length;
  }

  int get remindersTotal {
    return _todayRemindersForProgress.length;
  }

  double get dayProgressPercent {
    final total = routinesTotal + tasksTotal + remindersTotal;
    if (total == 0) return 0;

    final done = routinesDone + tasksDone + remindersDone;
    return (done / total).clamp(0, 1).toDouble();
  }

  List<TaskOutput> get focusTasks {
    final now = DateTime.now();
    final start = _startOfDay(now);
    final end = start.add(const Duration(days: 1));

    final list = openTasks.where((task) {
      final due = task.dueAt?.toLocal();
      if (due == null) return true;
      return due.isBefore(end);
    }).toList();

    list.sort((a, b) {
      final aDue = a.dueAt?.toLocal();
      final bDue = b.dueAt?.toLocal();
      final aPriority = _focusPriority(aDue, start, end);
      final bPriority = _focusPriority(bDue, start, end);

      final byPriority = aPriority.compareTo(bPriority);
      if (byPriority != 0) return byPriority;

      if (aPriority == 0 || aPriority == 1) {
        if (aDue != null && bDue != null) {
          final byDate = aDue.compareTo(bDue);
          if (byDate != 0) return byDate;
        }
      }

      if (aPriority == 2) {
        final aCreated = a.createdAt?.toLocal();
        final bCreated = b.createdAt?.toLocal();
        if (aCreated != null && bCreated != null) {
          final byCreatedDesc = bCreated.compareTo(aCreated);
          if (byCreatedDesc != 0) return byCreatedDesc;
        } else if (aCreated != null) {
          return -1;
        } else if (bCreated != null) {
          return 1;
        }
      }

      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    return list.take(5).toList(growable: false);
  }

  String get executiveSummary {
    if (totalOverdueCount > 0) {
      return '${TextUtils.countLabel(totalOverdueCount, 'item atrasado', 'itens atrasados')}. Bom momento para colocar o dia em dia.';
    }

    final commitmentsToday =
        eventsTodayCount + remindersTodayCount + routinesTotal + tasksTotal;
    final criticalOpen = focusTasks.length;

    if (commitmentsToday == 0 && criticalOpen == 0) {
      return 'Dia livre! Sem compromissos agendados.';
    }

    if (commitmentsToday == 0) {
      return 'Sem compromissos hoje, mas você tem ${TextUtils.countLabel(criticalOpen, 'tarefa crítica aberta', 'tarefas críticas abertas')}.';
    }

    if (criticalOpen == 0) {
      return 'Você tem ${TextUtils.countLabel(commitmentsToday, 'compromisso', 'compromissos')} hoje.';
    }

    return 'Você tem ${TextUtils.countLabel(commitmentsToday, 'compromisso', 'compromissos')} hoje e ${TextUtils.countLabel(criticalOpen, 'tarefa crítica aberta', 'tarefas críticas abertas')}.';
  }

  Map<DateTime, int> get weekDensityMap {
    final today = _startOfDay(DateTime.now());
    final start = today.subtract(Duration(days: today.weekday - 1));
    final end = start.add(const Duration(days: 7));

    final density = <DateTime, int>{
      for (var i = 0; i < 7; i++) start.add(Duration(days: i)): 0,
    };

    void increment(DateTime? raw) {
      if (raw == null) return;
      final local = raw.toLocal();
      final day = _startOfDay(local);
      if (day.isBefore(start) || !day.isBefore(end)) return;
      density[day] = (density[day] ?? 0) + 1;
    }

    for (final item in agenda.value.events) {
      increment(item.startAt);
    }
    for (final item in agenda.value.tasks) {
      increment(item.dueAt);
    }
    for (final item in agenda.value.reminders) {
      increment(item.remindAt);
    }

    for (final routine in routines.value) {
      final schedule = _routineStartAtToday(routine);
      if (schedule == null) continue;
      increment(schedule);
    }

    return Map.unmodifiable(density);
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

    result.fold((failure) {
      _setError(
        failure,
        fallback: 'Não foi possível atualizar a tarefa pela Home.',
      );
    }, _replaceTaskInAgenda);
  }

  Future<void> toggleRoutine(RoutineOutput routine, bool completed) async {
    if (_updatingRoutineIds.contains(routine.id)) return;

    _updatingRoutineIds.add(routine.id);
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final result = completed
        ? await _completeRoutineUsecase.call(routine.id, date: dateStr)
        : await _uncompleteRoutineUsecase.call(routine.id, dateStr);

    _updatingRoutineIds.remove(routine.id);

    result.fold(
      (failure) =>
          _setError(failure, fallback: 'Não foi possível atualizar a rotina.'),
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

  Future<void> markTimelineItemDone(String id, TimelineItemType type) async {
    final itemId = id.trim();
    if (itemId.isEmpty) return;

    switch (type) {
      case TimelineItemType.event:
        return;
      case TimelineItemType.task:
        await _markTaskDone(itemId);
        return;
      case TimelineItemType.reminder:
        await _markReminderDone(itemId);
        return;
      case TimelineItemType.routine:
        final routine = _findRoutineById(itemId);
        if (routine == null || routine.isCompletedToday) return;
        await toggleRoutine(routine, true);
        return;
    }
  }

  Future<void> _markTaskDone(String taskId) async {
    if (_updatingTaskIds.contains(taskId)) return;

    _updatingTaskIds.add(taskId);
    final result = await _updateTaskUsecase.call(
      TaskUpdateInput(id: taskId, status: 'DONE'),
    );
    _updatingTaskIds.remove(taskId);

    result.fold((failure) {
      _setError(
        failure,
        fallback: 'Não foi possível concluir a tarefa na timeline.',
      );
    }, _replaceTaskInAgenda);
  }

  Future<void> _markReminderDone(String reminderId) async {
    if (_updatingReminderIds.contains(reminderId)) return;

    _updatingReminderIds.add(reminderId);
    final result = await _updateReminderUsecase.call(
      ReminderUpdateInput(id: reminderId, status: 'DONE'),
    );
    _updatingReminderIds.remove(reminderId);

    result.fold((failure) {
      _setError(
        failure,
        fallback: 'Não foi possível concluir o lembrete na timeline.',
      );
    }, _replaceReminderInAgenda);
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

    try {
      final agendaFuture = _getAgendaUsecase.call(limit: 200);
      final listsFuture = _getShoppingListsUsecase.call(limit: 20);

      final now = DateTime.now();
      final weekday = now.weekday % 7;
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final routinesFuture = _getRoutinesByWeekdayUsecase.call(
        weekday,
        date: dateStr,
      );
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
      final summaryResult =
          results[3] as Either<Failure, RoutineTodaySummaryOutput>;

      agendaResult.fold(
        (failure) =>
            _setError(failure, fallback: 'Não foi possível carregar agenda.'),
        (output) => agenda.value = output,
      );

      summaryResult.fold(
        (_) => null,
        (summary) => routineSummary.value = summary,
      );

      routinesResult.fold(
        (failure) =>
            _setError(failure, fallback: 'Não foi possível carregar rotinas.'),
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
    } catch (_) {
      if (error.value == null || error.value!.isEmpty) {
        error.value = 'Não foi possível carregar a Home.';
      }
    } finally {
      loading.value = false;
      refreshing.value = false;
    }
  }

  List<TimelineItem> get _timelineItemsToday {
    final merged = <TimelineItem>[
      ..._agendaTimelineItemsToday,
      ..._routineTimelineItemsToday,
    ];

    merged.sort((a, b) {
      final byTime = a.scheduledTime.compareTo(b.scheduledTime);
      if (byTime != 0) return byTime;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    return merged;
  }

  List<TimelineItem> get _agendaTimelineItemsToday {
    final now = DateTime.now();
    final start = _startOfDay(now);
    final end = start.add(const Duration(days: 1));
    final items = <TimelineItem>[];

    for (final event in agenda.value.events) {
      final local = event.startAt?.toLocal();
      if (local == null || !_isWithinRange(local, start, end)) continue;
      if (!_hasDefinedTime(local)) continue;

      final subtitle = TextUtils.normalize(event.location);
      items.add(
        TimelineItem(
          id: event.id,
          title: event.title,
          subtitle: subtitle,
          type: TimelineItemType.event,
          scheduledTime: local,
          endScheduledTime: _eventEndAtLocal(event, startAtLocal: local),
          isCompleted: false,
          isOverdue: local.isBefore(now),
        ),
      );
    }

    for (final task in agenda.value.tasks) {
      final local = task.dueAt?.toLocal();
      if (local == null || !_isWithinRange(local, start, end)) continue;
      if (!_hasDefinedTime(local) || task.isDone) continue;

      items.add(
        TimelineItem(
          id: task.id,
          title: task.title,
          subtitle: TextUtils.normalize(task.description),
          type: TimelineItemType.task,
          scheduledTime: local,
          isCompleted: task.isDone,
          isOverdue: local.isBefore(now) && !task.isDone,
        ),
      );
    }

    for (final reminder in agenda.value.reminders) {
      final local = reminder.remindAt?.toLocal();
      if (local == null || !_isWithinRange(local, start, end)) continue;
      if (!_hasDefinedTime(local) || reminder.isDone) continue;

      items.add(
        TimelineItem(
          id: reminder.id,
          title: reminder.title,
          type: TimelineItemType.reminder,
          scheduledTime: local,
          isCompleted: reminder.isDone,
          isOverdue: local.isBefore(now) && !reminder.isDone,
        ),
      );
    }

    return items;
  }

  List<TimelineItem> get _routineTimelineItemsToday {
    final now = DateTime.now();
    final list = <TimelineItem>[];

    for (final routine in routines.value) {
      final scheduled = _routineStartAtToday(routine);
      if (scheduled == null || routine.isCompletedToday) continue;
      final endScheduled = _routineEndAtToday(routine, startAt: scheduled);

      list.add(
        TimelineItem(
          id: routine.id,
          title: routine.title,
          subtitle: TextUtils.normalize(routine.weekdaysLabel),
          type: TimelineItemType.routine,
          scheduledTime: scheduled,
          endScheduledTime: endScheduled,
          isCompleted: routine.isCompletedToday,
          isOverdue: scheduled.isBefore(now) && !routine.isCompletedToday,
        ),
      );
    }

    return list;
  }

  List<TaskOutput> get _todayTasksForProgress {
    final now = DateTime.now();
    return agenda.value.tasks
        .where((task) {
          final due = task.dueAt?.toLocal();
          if (due == null) return false;
          return _isSameDay(due, now);
        })
        .toList(growable: false);
  }

  List<ReminderOutput> get _todayRemindersForProgress {
    final now = DateTime.now();
    return agenda.value.reminders
        .where((item) {
          final remindAt = item.remindAt?.toLocal();
          if (remindAt == null) return false;
          return _isSameDay(remindAt, now);
        })
        .toList(growable: false);
  }

  int _focusPriority(DateTime? dueAt, DateTime dayStart, DateTime dayEnd) {
    if (dueAt == null) return 2;
    if (dueAt.isBefore(dayStart)) return 0;
    if (dueAt.isBefore(dayEnd)) return 1;
    return 3;
  }

  void _replaceTaskInAgenda(TaskOutput updatedTask) {
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
  }

  void _replaceReminderInAgenda(ReminderOutput updatedReminder) {
    final current = agenda.value;
    final reminders = List<ReminderOutput>.from(current.reminders);
    final reminderIndex = reminders.indexWhere(
      (item) => item.id == updatedReminder.id,
    );
    if (reminderIndex == -1) return;

    reminders[reminderIndex] = updatedReminder;
    agenda.value = AgendaOutput(
      events: current.events,
      tasks: current.tasks,
      reminders: reminders,
    );
  }

  RoutineOutput? _findRoutineById(String routineId) {
    for (final routine in routines.value) {
      if (routine.id == routineId) return routine;
    }
    return null;
  }

  bool _hasDefinedTime(DateTime date) {
    return date.hour != 0 ||
        date.minute != 0 ||
        date.second != 0 ||
        date.millisecond != 0 ||
        date.microsecond != 0;
  }

  bool _isWithinRange(DateTime value, DateTime start, DateTime end) {
    return !value.isBefore(start) && value.isBefore(end);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime? _routineStartAtToday(RoutineOutput routine) {
    final now = DateTime.now();
    return _parseRoutineTimeForDay(routine.startTime, now);
  }

  DateTime? _routineEndAtToday(
    RoutineOutput routine, {
    required DateTime startAt,
  }) {
    final parsed = _parseRoutineTimeForDay(routine.endTime, startAt);
    if (parsed == null) return null;
    if (!parsed.isAfter(startAt)) return null;
    return parsed;
  }

  DateTime? _parseRoutineTimeForDay(String raw, DateTime baseDate) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    final match = RegExp(r'(\d{1,2}):(\d{1,2})').firstMatch(value);
    if (match == null) return null;

    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
  }

  DateTime? _eventEndAtLocal(
    EventOutput event, {
    required DateTime startAtLocal,
  }) {
    final end = event.endAt?.toLocal();
    if (end == null) return null;
    if (!end.isAfter(startAtLocal)) return null;
    return end;
  }

  void _setError(Failure failure, {required String fallback}) {
    final message = TextUtils.normalize(failure.message);
    if (message != null) {
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
