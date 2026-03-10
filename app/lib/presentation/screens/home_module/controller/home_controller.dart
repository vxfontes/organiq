import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:inbota/modules/events/data/models/agenda_output.dart';
import 'package:inbota/modules/events/data/models/event_output.dart';
import 'package:inbota/modules/events/domain/usecases/delete_event_usecase.dart';
import 'package:inbota/modules/home/data/models/home_dashboard_output.dart';
import 'package:inbota/modules/home/domain/usecases/get_home_dashboard_usecase.dart';
import 'package:inbota/modules/inbox/data/models/inbox_confirm_input.dart';
import 'package:inbota/modules/inbox/data/models/inbox_create_input.dart';
import 'package:inbota/modules/inbox/data/models/inbox_create_line_result.dart';
import 'package:inbota/modules/inbox/data/models/inbox_item_output.dart';
import 'package:inbota/modules/inbox/domain/usecases/confirm_inbox_item_usecase.dart';
import 'package:inbota/modules/inbox/domain/usecases/create_inbox_item_usecase.dart';
import 'package:inbota/modules/inbox/domain/usecases/reprocess_inbox_item_usecase.dart';
import 'package:inbota/modules/reminders/data/models/reminder_output.dart';
import 'package:inbota/modules/reminders/data/models/reminder_update_input.dart';
import 'package:inbota/modules/reminders/domain/usecases/delete_reminder_usecase.dart';
import 'package:inbota/modules/reminders/domain/usecases/update_reminder_usecase.dart';
import 'package:inbota/modules/routines/data/models/routine_output.dart';
import 'package:inbota/modules/routines/data/models/routine_today_summary_output.dart';
import 'package:inbota/modules/routines/domain/usecases/complete_routine_usecase.dart';
import 'package:inbota/modules/routines/domain/usecases/delete_routine_usecase.dart';
import 'package:inbota/modules/routines/domain/usecases/uncomplete_routine_usecase.dart';
import 'package:inbota/modules/shopping/data/models/shopping_item_output.dart';
import 'package:inbota/modules/shopping/data/models/shopping_list_output.dart';
import 'package:inbota/modules/shopping/domain/usecases/delete_shopping_list_usecase.dart';
import 'package:inbota/modules/tasks/data/models/task_output.dart';
import 'package:inbota/modules/tasks/data/models/task_update_input.dart';
import 'package:inbota/modules/tasks/domain/usecases/delete_task_usecase.dart';
import 'package:inbota/modules/tasks/domain/usecases/update_task_usecase.dart';
import 'package:inbota/presentation/screens/home_module/components/timeline_item.dart';
import 'package:inbota/presentation/screens/home_module/utils/home_controller_utils.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/state/ib_state.dart';
import 'package:inbota/shared/utils/date_time.dart';
import 'package:inbota/shared/utils/text_utils.dart';

class HomeController implements IBController {
  HomeController(
    this._getHomeDashboardUsecase,
    this._updateTaskUsecase,
    this._updateReminderUsecase,
    this._completeRoutineUsecase,
    this._uncompleteRoutineUsecase,
    this._createInboxItemUsecase,
    this._reprocessInboxItemUsecase,
    this._confirmInboxItemUsecase,
    this._deleteTaskUsecase,
    this._deleteReminderUsecase,
    this._deleteEventUsecase,
    this._deleteShoppingListUsecase,
    this._deleteRoutineUsecase,
  );

  final GetHomeDashboardUsecase _getHomeDashboardUsecase;
  final UpdateTaskUsecase _updateTaskUsecase;
  final UpdateReminderUsecase _updateReminderUsecase;
  final CompleteRoutineUsecase _completeRoutineUsecase;
  final UncompleteRoutineUsecase _uncompleteRoutineUsecase;

  final CreateInboxItemUsecase _createInboxItemUsecase;
  final ReprocessInboxItemUsecase _reprocessInboxItemUsecase;
  final ConfirmInboxItemUsecase _confirmInboxItemUsecase;
  final DeleteTaskUsecase _deleteTaskUsecase;
  final DeleteReminderUsecase _deleteReminderUsecase;
  final DeleteEventUsecase _deleteEventUsecase;
  final DeleteShoppingListUsecase _deleteShoppingListUsecase;
  final DeleteRoutineUsecase _deleteRoutineUsecase;

  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<bool> refreshing = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);
  final ValueNotifier<HomeDashboardOutput?> dashboardData = ValueNotifier(null);

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
    final dashboard = dashboardData.value;
    if (dashboard == null) return false;
    return dashboard.timeline.isNotEmpty ||
        dashboard.shoppingPreview.isNotEmpty ||
        dashboard.focusTasks.isNotEmpty ||
        dashboard.dayProgress.routinesTotal > 0 ||
        dashboard.dayProgress.tasksTotal > 0 ||
        dashboard.weekDensity.values.any((value) => value > 0) ||
        (dashboard.eventsTodayCount ?? 0) > 0 ||
        (dashboard.remindersTodayCount ?? 0) > 0;
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
    final dashboardCount = dashboardData.value?.remindersTodayCount;
    return dashboardCount ?? 0;
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
    final dashboardCount = dashboardData.value?.eventsTodayCount;
    return dashboardCount ?? 0;
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
    final dashboard = dashboardData.value;
    if (dashboard == null) return const [];
    return dashboard.shoppingPreview
        .map(
          (item) => ShoppingListOutput(
            id: item.id,
            title: item.title,
            status: 'OPEN',
          ),
        )
        .toList(growable: false);
  }

  int get openShoppingListsCount {
    final dashboard = dashboardData.value;
    if (dashboard == null) return 0;
    return dashboard.shoppingPreview.length;
  }

  int get openShoppingLists => openShoppingListsCount;

  int get pendingShoppingItemsCount {
    final dashboard = dashboardData.value;
    if (dashboard == null) return 0;
    var total = 0;
    for (final list in dashboard.shoppingPreview) {
      total += list.pendingItems;
    }
    return total;
  }

  int get totalPendingShoppingItems => pendingShoppingItemsCount;

  int pendingItemsForList(String listId) {
    final dashboard = dashboardData.value;
    if (dashboard == null) return 0;
    for (final list in dashboard.shoppingPreview) {
      if (list.id == listId) return list.pendingItems;
    }
    return 0;
  }

  List<ShoppingListOutput> get homeShoppingListsPreview {
    final dashboard = dashboardData.value;
    if (dashboard == null) return const [];
    return dashboard.shoppingPreview
        .map(
          (item) => ShoppingListOutput(
            id: item.id,
            title: item.title,
            status: 'OPEN',
          ),
        )
        .toList(growable: false);
  }

  List<TimelineItem> get nextActionsTimeline {
    final dashboardTimeline = _dashboardTimelineForNextActions;
    if (dashboardTimeline.isEmpty) return const [];
    final now = DateTime.now();
    return dashboardTimeline
        .where((item) => !item.scheduledTime.isBefore(now))
        .take(10)
        .toList(growable: false);
  }

  List<TimelineItem> get pastActionsToday {
    final dashboardTimeline = _dashboardTimelineForInsights;
    if (dashboardTimeline.isEmpty) return const [];
    final now = DateTime.now();
    return dashboardTimeline
        .where((item) => item.scheduledTime.isBefore(now))
        .toList(growable: false);
  }

  List<TimelineItem> get insightsTimelineToday {
    final dashboardTimeline = _dashboardTimelineForInsights;
    return dashboardTimeline;
  }

  int get routinesDone {
    final dashboard = dashboardData.value;
    if (dashboard == null) return 0;
    return dashboard.dayProgress.routinesDone;
  }

  int get routinesTotal {
    final dashboard = dashboardData.value;
    if (dashboard == null) return 0;
    return dashboard.dayProgress.routinesTotal;
  }

  int get tasksDone {
    final dashboard = dashboardData.value;
    if (dashboard == null) return 0;
    return dashboard.dayProgress.tasksDone;
  }

  int get tasksTotal {
    final dashboard = dashboardData.value;
    if (dashboard == null) return 0;
    return dashboard.dayProgress.tasksTotal;
  }

  int get remindersDoneToday {
    final dashboard = dashboardData.value;
    if (dashboard == null || dashboard.timeline.isEmpty) return 0;

    var done = 0;
    final today = DateTime.now();
    for (final item in dashboard.timeline) {
      if (item.itemType != 'reminder') continue;
      if (!DateTimeUtils.isSameDay(item.scheduledTime.toLocal(), today)) {
        continue;
      }
      if (item.isCompleted) done += 1;
    }
    return done;
  }

  int get remindersTotalToday {
    final dashboard = dashboardData.value;
    if (dashboard == null || dashboard.timeline.isEmpty) return 0;

    var total = 0;
    final today = DateTime.now();
    for (final item in dashboard.timeline) {
      if (item.itemType != 'reminder') continue;
      if (!DateTimeUtils.isSameDay(item.scheduledTime.toLocal(), today)) {
        continue;
      }
      total += 1;
    }
    return total;
  }

  double get dayProgressPercent {
    final dashboard = dashboardData.value;
    if (dashboard == null) return 0;
    return dashboard.dayProgress.progressPercent.clamp(0, 1).toDouble();
  }

  List<TaskOutput> get focusTasks {
    final dashboard = dashboardData.value;
    if (dashboard == null) return const [];
    return dashboard.focusTasks.take(5).toList(growable: false);
  }

  Map<DateTime, int> get weekDensityMap {
    final dashboard = dashboardData.value;
    if (dashboard == null || dashboard.weekDensity.isEmpty) {
      return const <DateTime, int>{};
    }
    final density = <DateTime, int>{};
    dashboard.weekDensity.forEach((key, value) {
      final date = DateTimeUtils.parseDensityDay(key);
      if (date == null) return;
      density[date] = value;
    });
    return Map.unmodifiable(density);
  }

  String get insightTitle {
    final insight = dashboardData.value?.insight;
    if (insight == null) return '';
    return insight.title;
  }

  String get insightSummary {
    final insight = dashboardData.value?.insight;
    if (insight == null) return '';
    return insight.summary;
  }

  String get insightFooter {
    final insight = dashboardData.value?.insight;
    if (insight == null) return '';
    return insight.footer;
  }

  bool get insightIsFocus {
    return dashboardData.value?.insight?.isFocus == true;
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
      (task) {
        _replaceTaskInAgenda(task);
        _replaceTaskInDashboard(task);
      },
    );
  }

  Future<void> toggleRoutine(RoutineOutput routine, bool completed) async {
    if (_updatingRoutineIds.contains(routine.id)) return;

    _updatingRoutineIds.add(routine.id);
    final now = DateTime.now();
    final dateStr = DateTimeUtils.dateParamYmd(now);

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
        _replaceRoutineInDashboard(routine.id, completed);
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
        if (routine != null) {
          if (routine.isCompletedToday) return;
          await toggleRoutine(routine, true);
          return;
        }
        await _completeRoutineById(itemId);
        return;
    }
  }

  Future<void> _completeRoutineById(String routineId) async {
    if (_updatingRoutineIds.contains(routineId)) return;

    _updatingRoutineIds.add(routineId);
    final now = DateTime.now();
    final dateStr = DateTimeUtils.dateParamYmd(now);
    final result = await _completeRoutineUsecase.call(routineId, date: dateStr);
    _updatingRoutineIds.remove(routineId);

    result.fold(
      (failure) =>
          _setError(failure, fallback: 'Não foi possível atualizar a rotina.'),
      (_) {
        _replaceRoutineInDashboard(routineId, true);
        _refreshRoutineSummary();
      },
    );
  }

  Future<void> _markTaskDone(String taskId) async {
    if (_updatingTaskIds.contains(taskId)) return;

    _updatingTaskIds.add(taskId);
    final result = await _updateTaskUsecase.call(
      TaskUpdateInput(id: taskId, status: 'DONE'),
    );
    _updatingTaskIds.remove(taskId);

    result.fold(
      (failure) {
        _setError(
          failure,
          fallback: 'Não foi possível concluir a tarefa na timeline.',
        );
      },
      (task) {
        _replaceTaskInAgenda(task);
        _replaceTaskInDashboard(task);
      },
    );
  }

  Future<void> _markReminderDone(String reminderId) async {
    if (_updatingReminderIds.contains(reminderId)) return;

    _updatingReminderIds.add(reminderId);
    final result = await _updateReminderUsecase.call(
      ReminderUpdateInput(id: reminderId, status: 'DONE'),
    );
    _updatingReminderIds.remove(reminderId);

    result.fold(
      (failure) {
        _setError(
          failure,
          fallback: 'Não foi possível concluir o lembrete na timeline.',
        );
      },
      (reminder) {
        _replaceReminderInAgenda(reminder);
        _replaceReminderInDashboard(reminder);
      },
    );
  }

  Future<void> _refreshRoutineSummary() async {
    await _reloadDashboardAfterMutation();
  }

  Future<void> _reloadDashboardAfterMutation() async {
    final result = await _getHomeDashboardUsecase.call();
    result.fold((_) => null, _applyDashboard);
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
      final dashboardResult = await _getHomeDashboardUsecase.call();
      dashboardResult.fold((failure) {
        dashboardData.value = null;
        _setError(
          failure,
          fallback: 'Nao foi possivel carregar o dashboard da Home.',
        );
      }, _applyDashboard);
    } catch (_) {
      if (error.value == null || error.value!.isEmpty) {
        error.value = 'Não foi possível carregar a Home.';
      }
    } finally {
      loading.value = false;
      refreshing.value = false;
    }
  }

  void _applyDashboard(HomeDashboardOutput data) {
    dashboardData.value = data;
    routineSummary.value = RoutineTodaySummaryOutput(
      total: data.dayProgress.routinesTotal,
      completed: data.dayProgress.routinesDone,
    );

    agenda.value = const AgendaOutput(events: [], tasks: [], reminders: []);
    routines.value = const [];

    shoppingLists.value = data.shoppingPreview
        .map(
          (list) => ShoppingListOutput(
            id: list.id,
            title: list.title,
            status: 'OPEN',
          ),
        )
        .toList(growable: false);
    shoppingItemsByList.value = {
      for (final list in data.shoppingPreview)
        list.id: List.generate(
          list.pendingItems,
          (index) => ShoppingItemOutput(
            id: '${list.id}:$index',
            title: index < list.previewItems.length
                ? list.previewItems[index]
                : 'Item pendente',
            checked: false,
            sortOrder: index,
          ),
          growable: false,
        ),
    };
  }

  List<TimelineItem> get _dashboardTimelineForInsights {
    return _mapDashboardTimelineItems(includeCompleted: true);
  }

  List<TimelineItem> get _dashboardTimelineForNextActions {
    return _mapDashboardTimelineItems(includeCompleted: false);
  }

  List<TimelineItem> _mapDashboardTimelineItems({
    required bool includeCompleted,
  }) {
    final dashboard = dashboardData.value;
    if (dashboard == null || dashboard.timeline.isEmpty) return const [];

    final items = <TimelineItem>[];
    for (final item in dashboard.timeline) {
      final timelineType = HomeControllerUtils.timelineTypeFromRaw(
        item.itemType,
      );
      if (timelineType == null) continue;
      final localScheduled = item.scheduledTime.toLocal();
      if (localScheduled.millisecondsSinceEpoch <= 0) continue;
      if (!includeCompleted &&
          (timelineType == TimelineItemType.task ||
              timelineType == TimelineItemType.reminder ||
              timelineType == TimelineItemType.routine) &&
          item.isCompleted) {
        continue;
      }

      items.add(
        TimelineItem(
          id: item.id,
          title: item.title,
          subtitle: TextUtils.normalize(item.subtitle),
          type: timelineType,
          scheduledTime: localScheduled,
          endScheduledTime: item.endScheduledTime?.toLocal(),
          isCompleted: item.isCompleted,
          isOverdue: item.isOverdue,
        ),
      );
    }

    items.sort((a, b) {
      final byTime = a.scheduledTime.compareTo(b.scheduledTime);
      if (byTime != 0) return byTime;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return items;
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

  void _replaceTaskInDashboard(TaskOutput updatedTask) {
    final dashboard = dashboardData.value;
    if (dashboard == null) return;

    bool? previousDone;
    final timeline = dashboard.timeline
        .map((item) {
          if (item.id != updatedTask.id || item.itemType != 'task') return item;
          previousDone ??= item.isCompleted;
          return item.copyWith(isCompleted: updatedTask.isDone);
        })
        .toList(growable: false);

    final focus = List<TaskOutput>.from(dashboard.focusTasks);
    final idx = focus.indexWhere((item) => item.id == updatedTask.id);
    if (idx != -1) {
      previousDone ??= focus[idx].isDone;
      if (updatedTask.isDone) {
        focus.removeAt(idx);
      } else {
        focus[idx] = updatedTask;
      }
    }

    var dayProgress = dashboard.dayProgress;
    final dueAt = updatedTask.dueAt?.toLocal();
    final isTodayTask =
        dueAt != null && DateTimeUtils.isSameDay(dueAt, DateTime.now());
    if (isTodayTask &&
        previousDone != null &&
        previousDone != updatedTask.isDone) {
      final nextDone = dayProgress.tasksDone + (updatedTask.isDone ? 1 : -1);
      dayProgress = dayProgress.copyWith(
        tasksDone: nextDone.clamp(0, dayProgress.tasksTotal),
      );
    }

    dashboardData.value = dashboard.copyWith(
      timeline: timeline,
      focusTasks: focus,
      dayProgress: dayProgress,
    );
  }

  void _replaceReminderInDashboard(ReminderOutput updatedReminder) {
    final dashboard = dashboardData.value;
    if (dashboard == null) return;

    final timeline = dashboard.timeline
        .map((item) {
          if (item.id != updatedReminder.id || item.itemType != 'reminder') {
            return item;
          }
          return item.copyWith(isCompleted: updatedReminder.isDone);
        })
        .toList(growable: false);

    dashboardData.value = dashboard.copyWith(timeline: timeline);
  }

  void _replaceRoutineInDashboard(String routineId, bool completed) {
    final dashboard = dashboardData.value;
    if (dashboard == null) return;

    bool? previousDone;
    final timeline = dashboard.timeline
        .map((item) {
          if (item.id != routineId || item.itemType != 'routine') return item;
          previousDone ??= item.isCompleted;
          return item.copyWith(isCompleted: completed);
        })
        .toList(growable: false);

    var dayProgress = dashboard.dayProgress;
    if (previousDone != null && previousDone != completed) {
      final nextDone = dayProgress.routinesDone + (completed ? 1 : -1);
      dayProgress = dayProgress.copyWith(
        routinesDone: nextDone.clamp(0, dayProgress.routinesTotal),
      );
    }

    dashboardData.value = dashboard.copyWith(
      timeline: timeline,
      dayProgress: dayProgress,
    );
  }

  RoutineOutput? _findRoutineById(String routineId) {
    for (final routine in routines.value) {
      if (routine.id == routineId) return routine;
    }
    return null;
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

  Future<Either<String, CreateLineResult>> quickAdd(String text) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return const Left('Texto vazio.');

    final createResult = await _createInboxItemUsecase.call(
      InboxCreateInput(source: 'manual', rawText: cleaned),
    );

    final createdItem = createResult.fold<InboxItemOutput?>(
      (failure) => null,
      (item) => item,
    );

    if (createdItem == null) {
      return Left(HomeControllerUtils.failureMessage(createResult));
    }

    final reprocessResult = await _reprocessInboxItemUsecase.call(
      createdItem.id,
    );
    final processedItem = reprocessResult.fold<InboxItemOutput?>(
      (failure) => null,
      (item) => item,
    );

    if (processedItem == null) {
      return Left(HomeControllerUtils.failureMessage(reprocessResult));
    }

    final confirmInput = InboxConfirmInput.fromSuggestion(
      processedItem,
      fallbackTitle: cleaned,
    );

    if (!confirmInput.isValidForConfirm) {
      return const Left('A IA não retornou dados suficientes para confirmar.');
    }

    final confirmResult = await _confirmInboxItemUsecase.call(confirmInput);
    return await confirmResult.fold<Future<Either<String, CreateLineResult>>>(
      (failure) async {
        return Left(
          (failure.message?.trim().isNotEmpty ?? false)
              ? failure.message!.trim()
              : 'Falha ao confirmar item processado.',
        );
      },
      (output) async {
        await _reloadDashboardAfterMutation();
        final (type, id) = HomeControllerUtils.resolveEntityRef(output);
        return Right(
          CreateLineResult(
            sourceText: cleaned,
            status: CreateLineStatus.success,
            message: HomeControllerUtils.successMessage(type),
            entityId: id,
            entityType: type,
          ),
        );
      },
    );
  }

  Future<Either<Failure, Unit>> deleteQuickAddResult(
    CreateLineResult result,
  ) async {
    if (!result.canDelete) {
      return Left(
        DeleteFailure(message: 'Item não pode ser excluído no estado atual.'),
      );
    }

    final deleteResult = await _deleteByEntity(
      result.entityType,
      result.entityId!,
    );
    return await deleteResult.fold<Future<Either<Failure, Unit>>>(
      (failure) async => Left(failure),
      (_) async {
        await _reloadDashboardAfterMutation();
        return const Right(unit);
      },
    );
  }

  Future<Either<Failure, Unit>> _deleteByEntity(
    CreateEntityType type,
    String id,
  ) {
    switch (type) {
      case CreateEntityType.task:
        return _deleteTaskUsecase.call(id);
      case CreateEntityType.reminder:
        return _deleteReminderUsecase.call(id);
      case CreateEntityType.event:
        return _deleteEventUsecase.call(id);
      case CreateEntityType.shoppingList:
        return _deleteShoppingListUsecase.call(id);
      case CreateEntityType.routine:
        return _deleteRoutineUsecase.call(id);
      case CreateEntityType.unknown:
        return Future.value(
          Left(
            DeleteFailure(message: 'Tipo de item não suportado para exclusao.'),
          ),
        );
    }
  }

  @override
  void dispose() {
    loading.dispose();
    refreshing.dispose();
    error.dispose();
    dashboardData.dispose();
    agenda.dispose();
    routines.dispose();
    routineSummary.dispose();
    shoppingLists.dispose();
    shoppingItemsByList.dispose();
  }
}
