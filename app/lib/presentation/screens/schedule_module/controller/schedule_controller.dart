import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';

import 'package:inbota/modules/flags/data/models/flag_output.dart';
import 'package:inbota/modules/flags/data/models/subflag_output.dart';
import 'package:inbota/modules/flags/domain/usecases/get_flags_usecase.dart';
import 'package:inbota/modules/flags/domain/usecases/get_subflags_by_flag_usecase.dart';
import 'package:inbota/modules/routines/data/models/routine_completion_output.dart';
import 'package:inbota/modules/routines/data/models/routine_create_input.dart';
import 'package:inbota/modules/routines/data/models/routine_exception_input.dart';
import 'package:inbota/modules/routines/data/models/routine_output.dart';
import 'package:inbota/modules/routines/data/models/routine_section.dart';
import 'package:inbota/modules/routines/data/models/routine_streak_output.dart';
import 'package:inbota/modules/routines/data/models/routine_update_input.dart';
import 'package:inbota/modules/routines/data/models/routine_week_option.dart';
import 'package:inbota/modules/routines/domain/usecases/complete_routine_usecase.dart';
import 'package:inbota/modules/routines/domain/usecases/create_routine_exception_usecase.dart';
import 'package:inbota/modules/routines/domain/usecases/create_routine_usecase.dart';
import 'package:inbota/modules/routines/domain/usecases/delete_routine_usecase.dart';
import 'package:inbota/modules/routines/domain/usecases/get_routine_history_usecase.dart';
import 'package:inbota/modules/routines/domain/usecases/get_routine_streak_usecase.dart';
import 'package:inbota/modules/routines/domain/usecases/get_routines_by_weekday_usecase.dart';
import 'package:inbota/modules/routines/domain/usecases/get_routines_usecase.dart';
import 'package:inbota/modules/routines/domain/usecases/toggle_routine_usecase.dart';
import 'package:inbota/modules/routines/domain/usecases/uncomplete_routine_usecase.dart';
import 'package:inbota/modules/routines/domain/usecases/update_routine_usecase.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/state/ib_state.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class ScheduleController implements IBController {
  ScheduleController(
    this._getRoutinesByWeekdayUsecase,
    this._createRoutineUsecase,
    this._updateRoutineUsecase,
    this._deleteRoutineUsecase,
    this._getFlagsUsecase,
    this._getSubflagsByFlagUsecase,
    this._getRoutinesUsecase,
    this._completeRoutineUsecase,
    this._uncompleteRoutineUsecase,
    this._getRoutineHistoryUsecase,
    this._getRoutineStreakUsecase,
    this._toggleRoutineUsecase,
    this._createRoutineExceptionUsecase,
  );

  final GetRoutinesByWeekdayUsecase _getRoutinesByWeekdayUsecase;
  final CreateRoutineUsecase _createRoutineUsecase;
  final UpdateRoutineUsecase _updateRoutineUsecase;
  final DeleteRoutineUsecase _deleteRoutineUsecase;
  final GetFlagsUsecase _getFlagsUsecase;
  final GetSubflagsByFlagUsecase _getSubflagsByFlagUsecase;
  final GetRoutinesUsecase _getRoutinesUsecase;
  final CompleteRoutineUsecase _completeRoutineUsecase;
  final UncompleteRoutineUsecase _uncompleteRoutineUsecase;
  final GetRoutineHistoryUsecase _getRoutineHistoryUsecase;
  final GetRoutineStreakUsecase _getRoutineStreakUsecase;
  final ToggleRoutineUsecase _toggleRoutineUsecase;
  final CreateRoutineExceptionUsecase _createRoutineExceptionUsecase;

  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<bool> detailsLoading = ValueNotifier(false);
  final ValueNotifier<ScheduleViewMode> viewMode = ValueNotifier(ScheduleViewMode.daily);
  final ValueNotifier<String?> error = ValueNotifier(null);
  final ValueNotifier<List<RoutineOutput>> allRoutines = ValueNotifier([]);
  final ValueNotifier<List<RoutineOutput>> routines = ValueNotifier([]);
  final ValueNotifier<Map<RoutinePeriod, List<RoutineOutput>>> routinesByPeriod = ValueNotifier({});
  final ValueNotifier<Map<int, List<RoutineOutput>>> routinesByWeekdayInWeek = ValueNotifier({});
  final ValueNotifier<int> selectedWeekday = ValueNotifier(0);
  final ValueNotifier<int> selectedWeekOffset = ValueNotifier(0);
  final ValueNotifier<List<FlagOutput>> flags = ValueNotifier([]);
  final ValueNotifier<Map<String, List<SubflagOutput>>> subflagsByFlag =
      ValueNotifier({});
  
  final ValueNotifier<List<RoutineCompletionOutput>> currentRoutineHistory = ValueNotifier([]);
  final ValueNotifier<RoutineStreakOutput?> currentRoutineStreak = ValueNotifier(null);

  int _loadRevision = 0;

  final TextEditingController createTitleController = TextEditingController();
  final ValueNotifier<Set<int>> createSelectedWeekdays = ValueNotifier(<int>{});
  final ValueNotifier<String> createStartTime = ValueNotifier('08:00');
  final ValueNotifier<String?> createEndTime = ValueNotifier(null);
  final ValueNotifier<String> createRecurrenceType = ValueNotifier('weekly');
  final ValueNotifier<String?> createSelectedFlagId = ValueNotifier(null);
  final ValueNotifier<String?> createSelectedSubflagId = ValueNotifier(null);
  String? _editingRoutineId;
  final Set<String> _togglingRoutineIds = <String>{};

  static const List<String> weekdayTabLabels = [
    'SEG',
    'TER',
    'QUA',
    'QUI',
    'SEX',
    'SÁB',
    'DOM',
  ];

  static const List<WeekdayOption> weekdayChipOptions = [
    WeekdayOption('S', 1),
    WeekdayOption('T', 2),
    WeekdayOption('Q', 3),
    WeekdayOption('Q', 4),
    WeekdayOption('S', 5),
    WeekdayOption('S', 6),
    WeekdayOption('D', 0),
  ];

  static const List<RoutinePeriod> routinePeriodOrder = [
    RoutinePeriod.morning,
    RoutinePeriod.afternoon,
    RoutinePeriod.night,
    RoutinePeriod.allDay,
  ];

  static const Map<RoutinePeriod, String> routinePeriodLabels = {
    RoutinePeriod.morning: 'Manhã',
    RoutinePeriod.afternoon: 'Tarde',
    RoutinePeriod.night: 'Noite',
    RoutinePeriod.allDay: 'Dia todo',
  };

  @override
  void dispose() {
    loading.dispose();
    detailsLoading.dispose();
    viewMode.dispose();
    error.dispose();
    allRoutines.dispose();
    routines.dispose();
    routinesByPeriod.dispose();
    routinesByWeekdayInWeek.dispose();
    selectedWeekday.dispose();
    selectedWeekOffset.dispose();
    flags.dispose();
    subflagsByFlag.dispose();
    currentRoutineHistory.dispose();
    currentRoutineStreak.dispose();
    createSelectedWeekdays.dispose();
    createStartTime.dispose();
    createEndTime.dispose();
    createRecurrenceType.dispose();
    createSelectedFlagId.dispose();
    createSelectedSubflagId.dispose();
    createTitleController.dispose();
  }

  int get currentWeekday => DateTime.now().weekday % 7;
  int get selectedWeekdayIndex =>
      selectedWeekday.value == 0 ? 6 : selectedWeekday.value - 1;

  DateTime get _currentMonday {
    final now = DateTime.now();
    final daysSinceMonday = now.weekday - 1;
    final monday = now.subtract(Duration(days: daysSinceMonday));
    return DateTime(monday.year, monday.month, monday.day).add(Duration(days: selectedWeekOffset.value * 7));
  }

  List<DateTime> get currentWeekDays {
    final monday = _currentMonday;
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  void selectWeekOffset(int offset) {
    if (selectedWeekOffset.value == offset) return;
    selectedWeekOffset.value = offset;
    
    if (viewMode.value == ScheduleViewMode.daily) {
      loadRoutinesForWeekday(selectedWeekday.value);
    } else {
      loadFullWeek();
    }
  }

  bool get hasRoutines =>
      routinesByPeriod.value.values.any((list) => list.isNotEmpty);
  bool get shouldShowLoadingOverlay =>
      loading.value && routines.value.isEmpty;
  bool get isEditing => _editingRoutineId != null;
  String get formTitle => isEditing ? 'Editar Rotina' : 'Nova Rotina';
  String get formPrimaryLabel => isEditing ? 'Salvar alterações' : 'Criar rotina';
  List<RoutineSection> get routineSections {
    final sections = <RoutineSection>[];
    for (final period in routinePeriodOrder) {
      final items = routinesByPeriod.value[period] ?? [];
      if (items.isNotEmpty) {
        sections.add(
          RoutineSection(
            title: routinePeriodLabels[period] ?? '',
            items: items,
          ),
        );
      }
    }
    return sections;
  }

  void selectWeekdayIndex(int index) {
    final apiWeekday = (index + 1) % 7;
    selectWeekday(apiWeekday);
  }

  void toggleViewMode() {
    viewMode.value = viewMode.value == ScheduleViewMode.daily
        ? ScheduleViewMode.weekly
        : ScheduleViewMode.daily;
    
    if (viewMode.value == ScheduleViewMode.weekly) {
      loadFullWeek();
    } else {
      loadRoutinesForWeekday(selectedWeekday.value);
    }
  }

  Future<void> load() async {
    if (loading.value) return;
    loading.value = true;
    error.value = null;

    selectedWeekday.value = currentWeekday;

    await _loadFlags();
    await _loadAllRoutines();
    
    if (viewMode.value == ScheduleViewMode.daily) {
      await loadRoutinesForWeekday(selectedWeekday.value);
    } else {
      await loadFullWeek();
    }

    loading.value = false;
  }

  Future<void> _loadAllRoutines() async {
    final result = await _getRoutinesUsecase.call(limit: 1000);
    result.fold(
      (failure) {},
      (data) {
        allRoutines.value = data.items;
      },
    );
  }

  Future<void> _loadFlags() async {
    final result = await _getFlagsUsecase.call(limit: 100);
    result.fold(
      (failure) {},
      (data) {
        flags.value = _safeFlagItems(data.items);
      },
    );
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

  Future<void> selectWeekday(int weekday) async {
    if (selectedWeekday.value == weekday) return;
    selectedWeekday.value = weekday;
    await loadRoutinesForWeekday(weekday);
  }

  String _dateForWeekday(int weekday) {
    final index = weekday == 0 ? 6 : weekday - 1;
    final date = currentWeekDays[index];
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> loadRoutinesForWeekday(int weekday) async {
    final revision = ++_loadRevision;
    loading.value = true;
    try {
      final date = _dateForWeekday(weekday);
      final result = await _getRoutinesByWeekdayUsecase.call(weekday, date: date);

      if (revision != _loadRevision) return;

      result.fold(
        (failure) => _setError(
          failure,
          fallback: 'Não foi possível carregar as rotinas.',
        ),
        (data) {
          routines.value = data.items.where((r) => r.id.isNotEmpty).toList();
          _groupRoutinesByPeriod();
        },
      );
    } finally {
      if (revision == _loadRevision) loading.value = false;
    }
  }

  Future<void> loadFullWeek() async {
    final revision = ++_loadRevision;
    loading.value = true;
    
    try {
      final weekDays = currentWeekDays;
      final resultsMap = <int, List<RoutineOutput>>{};

      final futures = List.generate(7, (index) {
        final date = weekDays[index];
        final apiWeekday = date.weekday % 7;
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        return _getRoutinesByWeekdayUsecase.call(apiWeekday, date: dateStr);
      });

      final results = await Future.wait(futures);
      
      if (revision != _loadRevision) return;

      for (int i = 0; i < results.length; i++) {
        final date = weekDays[i];
        final apiWeekday = date.weekday % 7;
        results[i].fold(
          (_) => resultsMap[apiWeekday] = [],
          (data) => resultsMap[apiWeekday] = data.items,
        );
      }

      routinesByWeekdayInWeek.value = resultsMap;
    } finally {
      if (revision == _loadRevision) loading.value = false;
    }
  }

  Future<void> loadRoutineDetails(String id) async {
    detailsLoading.value = true;
    currentRoutineHistory.value = [];
    currentRoutineStreak.value = null;

    final results = await Future.wait([
      _getRoutineHistoryUsecase.call(id),
      _getRoutineStreakUsecase.call(id),
    ]);

    final historyResult = results[0] as Either<Failure, List<RoutineCompletionOutput>>;
    final streakResult = results[1] as Either<Failure, RoutineStreakOutput>;

    historyResult.fold((_) => null, (data) => currentRoutineHistory.value = data);
    streakResult.fold((_) => null, (data) => currentRoutineStreak.value = data);

    detailsLoading.value = false;
  }

  bool isRoutineScheduledFor(RoutineOutput routine, DateTime date) {
    if (!routine.isActive) return false;

    final apiWeekday = date.weekday % 7;
    if (!routine.weekdays.contains(apiWeekday)) return false;

    try {
      final startsOn = DateTime.parse(routine.startsOn);
      final compareDate = DateTime(date.year, date.month, date.day);
      if (compareDate.isBefore(DateTime(startsOn.year, startsOn.month, startsOn.day))) {
        return false;
      }
    } catch (_) {}

    // EndsOn check
    if (routine.endsOn != null) {
      try {
        final endsOn = DateTime.parse(routine.endsOn!);
        final compareDate = DateTime(date.year, date.month, date.day);
        if (compareDate.isAfter(DateTime(endsOn.year, endsOn.month, endsOn.day))) {
          return false;
        }
      } catch (_) {}
    }

    // Recurrence check (simplified for UI strip)
    if (routine.recurrenceType == 'weekly' || routine.recurrenceType == '') {
      return true;
    }

    // For biweekly/triweekly, we'd need more logic, but for a 7-day strip,
    // assuming it matches the current week's cycle is usually enough for visual feedback.
    return true;
  }

  void _groupRoutinesByPeriod() {
    final grouped = <RoutinePeriod, List<RoutineOutput>>{
      RoutinePeriod.morning: [],
      RoutinePeriod.afternoon: [],
      RoutinePeriod.night: [],
      RoutinePeriod.allDay: [],
    };

    for (final routine in routines.value) {
      final period = _getPeriodForTime(routine.startTime);
      grouped[period]!.add(routine);
    }

    for (final list in grouped.values) {
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    routinesByPeriod.value = grouped;
  }

  RoutinePeriod _getPeriodForTime(String time) {
    if (time.isEmpty) return RoutinePeriod.allDay;

    try {
      final hour = int.parse(time.split(':').first);
      if (hour >= 5 && hour < 12) return RoutinePeriod.morning;
      if (hour >= 12 && hour < 18) return RoutinePeriod.afternoon;
      return RoutinePeriod.night;
    } catch (_) {
      return RoutinePeriod.allDay;
    }
  }

  void resetCreateForm() {
    _editingRoutineId = null;
    createTitleController.text = '';
    createSelectedWeekdays.value = <int>{};
    createStartTime.value = '08:00';
    createEndTime.value = null;
    createRecurrenceType.value = 'weekly';
    createSelectedFlagId.value = null;
    createSelectedSubflagId.value = null;
    error.value = null;
  }

  void startEditRoutine(RoutineOutput routine) {
    _editingRoutineId = routine.id;
    error.value = null;
    createTitleController.text = routine.title;
    createSelectedWeekdays.value = routine.weekdays.toSet();
    createStartTime.value = _normalizeTimeValue(routine.startTime);
    createEndTime.value = _normalizeTimeValue(routine.endTime);
    createRecurrenceType.value = routine.recurrenceType;
    createSelectedFlagId.value = routine.flag?.id;
    createSelectedSubflagId.value = routine.subflag?.id;
    final flagId = routine.flag?.id;
    if (flagId != null && flagId.trim().isNotEmpty) {
      loadSubflags(flagId);
    }
  }

  void toggleCreateWeekday(int weekday) {
    final updated = Set<int>.from(createSelectedWeekdays.value);
    if (updated.contains(weekday)) {
      updated.remove(weekday);
    } else {
      updated.add(weekday);
    }
    createSelectedWeekdays.value = updated;
  }

  void setCreateStartTime(TimeOfDay time) {
    createStartTime.value = _formatTimeOfDay(time);
  }

  void setCreateEndTime(TimeOfDay? time) {
    createEndTime.value = time == null ? null : _formatTimeOfDay(time);
  }

  void setCreateRecurrenceType(String value) {
    createRecurrenceType.value = value;
  }

  void setCreateFlagId(String? id) {
    createSelectedFlagId.value = id;
    createSelectedSubflagId.value = null;
  }

  void setCreateSubflagId(String? id) {
    createSelectedSubflagId.value = id;
  }

  Future<bool> submitRoutineForm() async {
    final trimmed = createTitleController.text.trim();
    if (trimmed.isEmpty) {
      error.value = 'Informe um título para a rotina.';
      return false;
    }

    final weekdays = createSelectedWeekdays.value.toList()..sort();
    if (weekdays.isEmpty) {
      error.value = 'Selecione pelo menos um dia da semana.';
      return false;
    }

    final startTime = createStartTime.value.trim();
    final endTime = createEndTime.value?.trim() ?? '';
    if (startTime.isEmpty || endTime.isEmpty) {
      error.value = 'Informe o horário de início e término.';
      return false;
    }

    if (_timeToMinutes(endTime) <= _timeToMinutes(startTime)) {
      error.value = 'O horário de término deve ser após o de início.';
      return false;
    }

    if (_hasOverlap(
      weekdays: weekdays,
      startTime: startTime,
      endTime: endTime,
      excludeId: _editingRoutineId,
    )) {
      error.value = 'Já existe uma rotina neste horário em um dos dias selecionados.';
      return false;
    }

    if (isEditing) {
      return updateRoutine(
        id: _editingRoutineId!,
        title: trimmed,
        weekdays: weekdays,
        startTime: startTime,
        endTime: endTime,
        recurrenceType: createRecurrenceType.value,
        flagId: createSelectedFlagId.value,
        subflagId: createSelectedSubflagId.value,
      );
    }

    return createRoutine(
      title: trimmed,
      weekdays: weekdays,
      startTime: startTime,
      endTime: endTime,
      recurrenceType: createRecurrenceType.value,
      flagId: createSelectedFlagId.value,
      subflagId: createSelectedSubflagId.value,
    );
  }

  bool _hasOverlap({
    required List<int> weekdays,
    required String startTime,
    required String endTime,
    String? excludeId,
  }) {
    final start = _timeToMinutes(startTime);
    final end = _timeToMinutes(endTime);

    for (final routine in allRoutines.value) {
      if (routine.id == excludeId || !routine.isActive) continue;

      final routineWeekdays = routine.weekdays.toSet();
      final hasCommonWeekday = weekdays.any((d) => routineWeekdays.contains(d));
      if (!hasCommonWeekday) continue;

      final rStart = _timeToMinutes(routine.startTime);
      final rEnd = _timeToMinutes(routine.endTime);

      if (start < rEnd && rStart < end) {
        return true;
      }
    }
    return false;
  }

  int _timeToMinutes(String time) {
    try {
      final parts = time.split(':');
      if (parts.length < 2) return 0;
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } catch (_) {
      return 0;
    }
  }

  Future<bool> createRoutine({
    required String title,
    required List<int> weekdays,
    required String startTime,
    required String endTime,
    String recurrenceType = 'weekly',
    String? flagId,
    String? subflagId,
  }) async {
    if (loading.value) return false;
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      error.value = 'Informe um título para a rotina.';
      return false;
    }

    if (weekdays.isEmpty) {
      error.value = 'Selecione pelo menos um dia da semana.';
      return false;
    }

    if (startTime.isEmpty || endTime.isEmpty) {
      error.value = 'Informe o horário de início e término.';
      return false;
    }

    if (_timeToMinutes(endTime) <= _timeToMinutes(startTime)) {
      error.value = 'O horário de término deve ser após o de início.';
      return false;
    }

    loading.value = true;
    error.value = null;

    final result = await _createRoutineUsecase.call(
      RoutineCreateInput(
        title: trimmed,
        weekdays: weekdays,
        startTime: startTime,
        endTime: endTime,
        recurrenceType: recurrenceType,
        flagId: flagId,
        subflagId: subflagId,
      ),
    );

    loading.value = false;

    return result.fold(
      (failure) {
        _setError(failure, fallback: 'Não foi possível criar a rotina.');
        return false;
      },
      (created) {
        allRoutines.value = [...allRoutines.value, created];
        if (viewMode.value == ScheduleViewMode.daily) {
          if (created.weekdays.contains(selectedWeekday.value)) {
            routines.value = [...routines.value, created];
            _groupRoutinesByPeriod();
          }
        } else {
          loadFullWeek();
        }
        return true;
      },
    );
  }

  Future<bool> updateRoutine({
    required String id,
    required String title,
    required List<int> weekdays,
    required String startTime,
    required String endTime,
    String recurrenceType = 'weekly',
    String? flagId,
    String? subflagId,
  }) async {
    if (loading.value) return false;

    loading.value = true;
    error.value = null;

    final result = await _updateRoutineUsecase.call(
      id,
      RoutineUpdateInput(
        title: title,
        weekdays: weekdays,
        startTime: startTime,
        endTime: endTime,
        recurrenceType: recurrenceType,
        flagId: flagId,
        subflagId: subflagId,
      ),
    );

    loading.value = false;

    return result.fold(
      (failure) {
        _setError(failure, fallback: 'Não foi possível atualizar a rotina.');
        return false;
      },
      (updated) {
        allRoutines.value = allRoutines.value.map((r) => r.id == updated.id ? updated : r).toList();
        
        if (viewMode.value == ScheduleViewMode.daily) {
          final list = routines.value.where((r) => r.id != updated.id).toList();
          if (updated.weekdays.contains(selectedWeekday.value)) {
            list.add(updated);
          }
          routines.value = list;
          _groupRoutinesByPeriod();
        } else {
          loadFullWeek();
        }
        return true;
      },
    );
  }

  Future<void> toggleRoutine(RoutineOutput routine, bool completed) async {
    if (_togglingRoutineIds.contains(routine.id)) return;

    _togglingRoutineIds.add(routine.id);
    final dateStr = _dateForWeekday(selectedWeekday.value);

    final result = completed 
      ? await _completeRoutineUsecase.call(routine.id, date: dateStr)
      : await _uncompleteRoutineUsecase.call(routine.id, dateStr);
    
    _togglingRoutineIds.remove(routine.id);

    result.fold(
      (failure) => _setError(failure, fallback: 'Não foi possível atualizar a rotina.'),
      (_) {
        final list = List<RoutineOutput>.from(routines.value);
        final idx = list.indexWhere((r) => r.id == routine.id);
        if (idx != -1) {
          list[idx] = list[idx].copyWith(isCompletedToday: completed);
          routines.value = list;
          _groupRoutinesByPeriod();
        }
        // Refresh history and streak if details are being shown
        loadRoutineDetails(routine.id);
      },
    );
  }

  Future<void> toggleRoutineActive(RoutineOutput routine, bool isActive) async {
    loading.value = true;
    final result = await _toggleRoutineUsecase.call(routine.id, isActive);
    loading.value = false;

    result.fold(
      (failure) => _setError(failure, fallback: 'Não foi possível alterar o status da rotina.'),
      (_) {
        final updated = routine.copyWith(isActive: isActive);
        allRoutines.value = allRoutines.value.map((r) => r.id == routine.id ? updated : r).toList();
        if (viewMode.value == ScheduleViewMode.daily) {
          routines.value = routines.value.map((r) => r.id == routine.id ? updated : r).toList();
          _groupRoutinesByPeriod();
        } else {
          loadFullWeek();
        }
      },
    );
  }

  Future<bool> skipToday(RoutineOutput routine) async {
    if (loading.value) return false;
    loading.value = true;
    error.value = null;

    final dateStr = _dateForWeekday(selectedWeekday.value);
    final result = await _createRoutineExceptionUsecase.call(
      routine.id,
      RoutineExceptionInput(
        exceptionDate: dateStr,
        action: 'skip',
      ),
    );

    loading.value = false;

    return result.fold(
      (failure) {
        _setError(failure, fallback: 'Não foi possível pular a rotina hoje.');
        return false;
      },
      (_) {
        if (viewMode.value == ScheduleViewMode.daily) {
          loadRoutinesForWeekday(selectedWeekday.value);
        } else {
          loadFullWeek();
        }
        return true;
      },
    );
  }

  Future<bool> deleteRoutine(String routineId) async {
    final result = await _deleteRoutineUsecase.call(routineId);

    return result.fold(
      (failure) {
        _setError(failure, fallback: 'Não foi possível excluir a rotina.');
        return false;
      },
      (_) {
        allRoutines.value = allRoutines.value.where((r) => r.id != routineId).toList();
        if (viewMode.value == ScheduleViewMode.daily) {
          routines.value = routines.value.where((r) => r.id != routineId).toList();
          _groupRoutinesByPeriod();
        } else {
          loadFullWeek();
        }
        return true;
      },
    );
  }

  List<RoutineOutput> getConflicts(RoutineOutput routine) {
    final conflicts = <RoutineOutput>[];
    final start = _timeToMinutes(routine.startTime);
    final end = routine.endTime.isNotEmpty
        ? _timeToMinutes(routine.endTime)
        : start + 1;

    for (final r in allRoutines.value) {
      if (r.id == routine.id || !r.isActive) continue;

      final routineWeekdays = r.weekdays.toSet();
      final hasCommonWeekday =
          routine.weekdays.any((d) => routineWeekdays.contains(d));
      if (!hasCommonWeekday) continue;

      final rStart = _timeToMinutes(r.startTime);
      final rEnd = r.endTime.isNotEmpty
          ? _timeToMinutes(r.endTime)
          : rStart + 1;

      if (start < rEnd && rStart < end) {
        conflicts.add(r);
      }
    }
    return conflicts;
  }

  Color routineTagColor(RoutineOutput routine) {
    final rawColor = routine.flagColor;
    if (rawColor == null || rawColor.trim().isEmpty) {
      return AppColors.primary700;
    }

    final parsed = int.tryParse(rawColor.replaceFirst('#', '0xFF'));
    if (parsed == null) return AppColors.primary700;
    return Color(parsed);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _normalizeTimeValue(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    final parts = value.split(':');
    if (parts.length >= 2) {
      final hour = parts[0].padLeft(2, '0');
      final minute = parts[1].padLeft(2, '0');
      return '$hour:$minute';
    }
    return value;
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

  void _setError(Failure failure, {required String fallback}) {
    final message = failure.message?.trim();
    if (message != null && message.isNotEmpty) {
      error.value = message;
    } else if (error.value == null || error.value!.isEmpty) {
      error.value = fallback;
    }
  }
}

enum RoutinePeriod { morning, afternoon, night, allDay }

enum ScheduleViewMode { daily, weekly }
