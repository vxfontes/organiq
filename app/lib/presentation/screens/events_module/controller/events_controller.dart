import 'package:flutter/material.dart';
import 'package:inbota/modules/flags/data/models/flag_output.dart';
import 'package:inbota/modules/flags/data/models/subflag_output.dart';
import 'package:inbota/modules/flags/domain/usecases/get_flags_usecase.dart';
import 'package:inbota/modules/flags/domain/usecases/get_subflags_by_flag_usecase.dart';
import 'package:inbota/modules/events/data/models/event_create_input.dart';
import 'package:inbota/modules/events/domain/usecases/create_event_usecase.dart';
import 'package:inbota/modules/events/data/models/event_output.dart';
import 'package:inbota/modules/events/domain/usecases/delete_event_usecase.dart';
import 'package:inbota/modules/events/domain/usecases/get_agenda_usecase.dart';
import 'package:inbota/modules/reminders/data/models/reminder_output.dart';
import 'package:inbota/modules/reminders/domain/usecases/delete_reminder_usecase.dart';
import 'package:inbota/modules/tasks/data/models/task_output.dart';
import 'package:inbota/modules/tasks/domain/usecases/delete_task_usecase.dart';
import 'package:inbota/presentation/screens/events_module/components/event_feed_item.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/state/ib_state.dart';
import 'package:inbota/shared/utils/text_utils.dart';

class EventsController implements IBController {
  EventsController(
    this._getAgendaUsecase,
    this._deleteEventUsecase,
    this._deleteTaskUsecase,
    this._deleteReminderUsecase,
    this._createEventUsecase,
    this._getFlagsUsecase,
    this._getSubflagsByFlagUsecase,
  );

  final GetAgendaUsecase _getAgendaUsecase;
  final DeleteEventUsecase _deleteEventUsecase;
  final DeleteTaskUsecase _deleteTaskUsecase;
  final DeleteReminderUsecase _deleteReminderUsecase;
  final CreateEventUsecase _createEventUsecase;
  final GetFlagsUsecase _getFlagsUsecase;
  final GetSubflagsByFlagUsecase _getSubflagsByFlagUsecase;

  final weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];
  final months = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];

  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);
  final ValueNotifier<List<FlagOutput>> flags = ValueNotifier([]);
  final ValueNotifier<Map<String, List<SubflagOutput>>> subflagsByFlag =
      ValueNotifier({});
  final ValueNotifier<EventFeedFilter> selectedFilter = ValueNotifier(
    EventFeedFilter.all,
  );
  final ValueNotifier<DateTime> selectedDate = ValueNotifier(
    _startOfDay(DateTime.now()),
  );
  final ValueNotifier<List<DateTime>> calendarDays = ValueNotifier(
    const <DateTime>[],
  );
  final ValueNotifier<List<EventFeedItem>> allItems = ValueNotifier(
    const <EventFeedItem>[],
  );
  final ValueNotifier<List<EventFeedItem>> visibleItems = ValueNotifier(
    const <EventFeedItem>[],
  );

  @override
  void dispose() {
    loading.dispose();
    error.dispose();
    flags.dispose();
    subflagsByFlag.dispose();
    selectedFilter.dispose();
    selectedDate.dispose();
    calendarDays.dispose();
    allItems.dispose();
    visibleItems.dispose();
  }

  Future<void> load() async {
    if (loading.value) return;

    loading.value = true;
    error.value = null;

    final merged = <EventFeedItem>[];

    final agendaResult = await _getAgendaUsecase.call(limit: 200);
    agendaResult.fold(
      (failure) {
        _setError(failure, fallback: 'Não foi possível carregar agenda.');
      },
      (output) {
        merged.addAll(_eventItems(output.events));
        merged.addAll(_taskItems(output.tasks));
        merged.addAll(_reminderItems(output.reminders));
      },
    );

    merged.sort((a, b) => a.date.compareTo(b.date));
    allItems.value = merged;

    final flagsResult = await _getFlagsUsecase.call(limit: 100);
    flagsResult.fold(
      (failure) =>
          _setError(failure, fallback: 'Não foi possível carregar flags.'),
      (data) => flags.value = _safeFlagItems(data.items),
    );

    _rebuildCalendarDays();
    _rebuildVisibleItems();
    loading.value = false;
  }

  Future<void> loadSubflags(String flagId) async {
    final trimmed = flagId.trim();
    if (trimmed.isEmpty) return;
    if (subflagsByFlag.value.containsKey(trimmed)) return;

    final result = await _getSubflagsByFlagUsecase.call(
      flagId: trimmed,
      limit: 100,
    );
    result.fold(
      (failure) =>
          _setError(failure, fallback: 'Não foi possível carregar subflags.'),
      (output) {
        final next = Map<String, List<SubflagOutput>>.from(
          subflagsByFlag.value,
        );
        next[trimmed] = _safeSubflagItems(output.items);
        subflagsByFlag.value = next;
      },
    );
  }

  void selectDate(DateTime date) {
    final next = _startOfDay(date);
    if (_isSameDay(next, selectedDate.value)) return;
    selectedDate.value = next;
    _rebuildVisibleItems();
  }

  void selectFilter(EventFeedFilter filter) {
    if (selectedFilter.value == filter) return;
    selectedFilter.value = filter;
    _rebuildVisibleItems();
  }

  String filterLabel(EventFeedFilter filter) {
    switch (filter) {
      case EventFeedFilter.all:
        return 'Todos';
      case EventFeedFilter.events:
        return 'Eventos';
      case EventFeedFilter.todos:
        return 'Tarefas';
      case EventFeedFilter.reminders:
        return 'Lembretes';
    }
  }

  bool matchesFilter(EventFeedItem item, EventFeedFilter filter) {
    switch (filter) {
      case EventFeedFilter.all:
        return true;
      case EventFeedFilter.events:
        return item.type == EventFeedItemType.event;
      case EventFeedFilter.todos:
        return item.type == EventFeedItemType.todo;
      case EventFeedFilter.reminders:
        return item.type == EventFeedItemType.reminder;
    }
  }

  List<EventFeedItem> _eventItems(List<EventOutput> events) {
    return events
        .where((event) => event.id.isNotEmpty && event.startAt != null)
        .map((event) => _eventItem(event))
        .toList(growable: false);
  }

  EventFeedItem _eventItem(EventOutput event) {
    return EventFeedItem(
      id: event.id,
      type: EventFeedItemType.event,
      title: event.title,
      date: event.startAt!.toLocal(),
      endDate: event.endAt?.toLocal(),
      secondary: event.location,
      flagLabel: TextUtils.normalize(event.flagName),
      subflagLabel: TextUtils.normalize(event.subflagName),
      flagColor: TextUtils.normalize(event.flagColor),
      subflagColor: TextUtils.normalize(event.subflagColor),
      allDay: event.allDay,
    );
  }

  List<EventFeedItem> _taskItems(List<TaskOutput> tasks) {
    return tasks
        .where((task) => task.id.isNotEmpty && task.dueAt != null)
        .map(
          (task) => EventFeedItem(
            id: task.id,
            type: EventFeedItemType.todo,
            title: task.title,
            date: task.dueAt!.toLocal(),
            secondary: task.description,
            flagLabel: TextUtils.normalize(task.flagName),
            subflagLabel: TextUtils.normalize(task.subflagName),
            flagColor: TextUtils.normalize(task.flagColor),
            subflagColor: TextUtils.normalize(task.subflagColor),
            done: task.isDone,
            allDay: task.dueAt!.hour == 0 && task.dueAt!.minute == 0,
          ),
        )
        .toList(growable: false);
  }

  List<EventFeedItem> _reminderItems(List<ReminderOutput> reminders) {
    return reminders
        .where(
          (reminder) => reminder.id.isNotEmpty && reminder.remindAt != null,
        )
        .map(
          (reminder) => EventFeedItem(
            id: reminder.id,
            type: EventFeedItemType.reminder,
            title: reminder.title,
            date: reminder.remindAt!.toLocal(),
            done: reminder.isDone,
            allDay:
                reminder.remindAt!.hour == 0 && reminder.remindAt!.minute == 0,
            flagLabel: TextUtils.normalize(reminder.flagName),
            subflagLabel: TextUtils.normalize(reminder.subflagName),
            flagColor: TextUtils.normalize(reminder.flagColor),
            subflagColor: TextUtils.normalize(reminder.subflagColor),
          ),
        )
        .toList(growable: false);
  }

  Future<bool> createEvent({
    required String title,
    required DateTime? startAt,
    required DateTime? endAt,
    String? location,
    String? flagId,
    String? subflagId,
  }) async {
    if (loading.value) return false;
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      error.value = 'Informe um título para o evento.';
      return false;
    }
    if (startAt == null || endAt == null) {
      error.value = 'Defina data de início e fim do evento.';
      return false;
    }
    if (endAt.isBefore(startAt)) {
      error.value = 'A data de fim precisa ser após o início.';
      return false;
    }

    loading.value = true;
    error.value = null;

    final result = await _createEventUsecase.call(
      EventCreateInput(
        title: trimmed,
        startAt: startAt,
        endAt: endAt,
        allDay: false,
        location: location,
        flagId: flagId,
        subflagId: subflagId,
      ),
    );

    loading.value = false;

    return result.fold(
      (failure) {
        _setError(failure, fallback: 'Não foi possível criar o evento.');
        return false;
      },
      (created) {
        if (created.startAt == null) return false;
        final next = List<EventFeedItem>.from(allItems.value)
          ..add(_eventItem(created));
        next.sort((a, b) => a.date.compareTo(b.date));
        allItems.value = next;
        _rebuildCalendarDays();
        _rebuildVisibleItems();
        return true;
      },
    );
  }

  void _rebuildCalendarDays() {
    final now = _startOfDay(DateTime.now());

    DateTime start = now.subtract(const Duration(days: 5));
    DateTime end = now.add(const Duration(days: 21));

    if (allItems.value.isNotEmpty) {
      final maxDate = _startOfDay(allItems.value.last.date);
      if (maxDate.isAfter(end)) end = maxDate;
    }

    final days = <DateTime>[];
    var current = start;
    var guard = 0;
    while (!current.isAfter(end) && guard < 120) {
      days.add(current);
      current = current.add(const Duration(days: 1));
      guard++;
    }

    calendarDays.value = days;

    final selected = _startOfDay(selectedDate.value);
    final selectedExists = days.any((day) => _isSameDay(day, selected));
    if (!selectedExists) {
      selectedDate.value = days.isNotEmpty ? days.first : now;
    }
  }

  void _rebuildVisibleItems() {
    final selected = _startOfDay(selectedDate.value);
    final filter = selectedFilter.value;

    final filtered =
        allItems.value
            .where((item) {
              if (!_isSameDay(item.date, selected)) return false;
              return matchesFilter(item, filter);
            })
            .toList(growable: false)
          ..sort((a, b) => a.date.compareTo(b.date));

    visibleItems.value = filtered;
  }

  Future<bool> deleteVisibleItem(EventFeedItem item) async {
    final result = switch (item.type) {
      EventFeedItemType.event => await _deleteEventUsecase.call(item.id),
      EventFeedItemType.todo => await _deleteTaskUsecase.call(item.id),
      EventFeedItemType.reminder => await _deleteReminderUsecase.call(item.id),
    };

    return result.fold(
      (failure) {
        _setError(
          failure,
          fallback: 'Não foi possível excluir item da agenda.',
        );
        return false;
      },
      (_) {
        final next = List<EventFeedItem>.from(allItems.value)
          ..removeWhere(
            (entry) => entry.id == item.id && entry.type == item.type,
          );
        allItems.value = next;
        _rebuildCalendarDays();
        _rebuildVisibleItems();
        return true;
      },
    );
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

  static DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<FlagOutput> _safeFlagItems(List<FlagOutput> items) {
    final safe = items.where((item) => item.id.isNotEmpty).toList();
    safe.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return safe;
  }

  List<SubflagOutput> _safeSubflagItems(List<SubflagOutput> items) {
    final safe = items.where((item) => item.id.isNotEmpty).toList();
    safe.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return safe;
  }
}

enum EventFeedFilter { all, events, todos, reminders }
