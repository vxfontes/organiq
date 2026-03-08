import 'package:flutter/material.dart';

import 'package:inbota/modules/flags/data/models/flag_output.dart';
import 'package:inbota/modules/flags/domain/usecases/get_flags_usecase.dart';
import 'package:inbota/modules/routines/data/models/routine_create_input.dart';
import 'package:inbota/modules/routines/data/models/routine_output.dart';
import 'package:inbota/modules/routines/domain/usecases/routine_usecases.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/state/ib_state.dart';
import 'package:inbota/shared/theme/app_colors.dart';

enum RoutinePeriod { morning, afternoon, night, allDay }

class WeekdayOption {
  const WeekdayOption(this.label, this.value);

  final String label;
  final int value;
}

class RoutineSection {
  const RoutineSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<RoutineOutput> items;
}

class ScheduleController implements IBController {
  ScheduleController(
    this._getRoutinesByWeekdayUsecase,
    this._createRoutineUsecase,
    this._updateRoutineUsecase,
    this._deleteRoutineUsecase,
    this._completeRoutineUsecase,
    this._uncompleteRoutineUsecase,
    this._getTodaySummaryUsecase,
    this._getFlagsUsecase,
  );

  final GetRoutinesByWeekdayUsecase _getRoutinesByWeekdayUsecase;
  final CreateRoutineUsecase _createRoutineUsecase;
  final UpdateRoutineUsecase _updateRoutineUsecase;
  final DeleteRoutineUsecase _deleteRoutineUsecase;
  final CompleteRoutineUsecase _completeRoutineUsecase;
  final UncompleteRoutineUsecase _uncompleteRoutineUsecase;
  final GetTodaySummaryUsecase _getTodaySummaryUsecase;
  final GetFlagsUsecase _getFlagsUsecase;

  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);
  final ValueNotifier<List<RoutineOutput>> routines = ValueNotifier([]);
  final ValueNotifier<Map<RoutinePeriod, List<RoutineOutput>>> routinesByPeriod =
      ValueNotifier({});
  final ValueNotifier<int> selectedWeekday = ValueNotifier(0);
  final ValueNotifier<List<FlagOutput>> flags = ValueNotifier([]);
  final ValueNotifier<int> todayTotal = ValueNotifier(0);
  final ValueNotifier<int> todayCompleted = ValueNotifier(0);
  final Set<String> _completedRoutineIds = <String>{};
  bool _routinesLoading = false;

  final TextEditingController createTitleController = TextEditingController();
  final ValueNotifier<Set<int>> createSelectedWeekdays = ValueNotifier(<int>{});
  final ValueNotifier<String> createStartTime = ValueNotifier('08:00');
  final ValueNotifier<String?> createEndTime = ValueNotifier(null);
  final ValueNotifier<String> createRecurrenceType = ValueNotifier('weekly');
  final ValueNotifier<String?> createSelectedFlagId = ValueNotifier(null);

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
    error.dispose();
    routines.dispose();
    routinesByPeriod.dispose();
    selectedWeekday.dispose();
    flags.dispose();
    todayTotal.dispose();
    todayCompleted.dispose();
    createSelectedWeekdays.dispose();
    createStartTime.dispose();
    createEndTime.dispose();
    createRecurrenceType.dispose();
    createSelectedFlagId.dispose();
    createTitleController.dispose();
  }

  int get currentWeekday => DateTime.now().weekday % 7;
  int get selectedWeekdayIndex =>
      selectedWeekday.value == 0 ? 6 : selectedWeekday.value - 1;

  bool get hasTodaySummary => todayTotal.value > 0;
  bool get shouldShowProgress => todayTotal.value > 0;
  bool get hasRoutines =>
      routinesByPeriod.value.values.any((list) => list.isNotEmpty);
  bool get shouldShowLoadingOverlay =>
      loading.value && routines.value.isEmpty;
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

  String get todayProgressLabel {
    return '${todayCompleted.value}/${todayTotal.value} concluídas hoje';
  }

  String get todayPercentageLabel => '${todayPercentage}%';

  double get todayProgress {
    final total = todayTotal.value;
    if (total <= 0) return 0;
    return todayCompleted.value / total;
  }

  int get todayPercentage => (todayProgress * 100).toInt();

  void selectWeekdayIndex(int index) {
    final apiWeekday = (index + 1) % 7;
    selectWeekday(apiWeekday);
  }

  Future<void> load() async {
    if (loading.value) return;
    loading.value = true;
    error.value = null;

    selectedWeekday.value = currentWeekday;

    await _loadSummary();
    await _loadFlags();
    await loadRoutinesForWeekday(selectedWeekday.value);

    loading.value = false;
  }

  Future<void> _loadSummary() async {
    final result = await _getTodaySummaryUsecase.call();
    result.fold(
      (failure) {},
      (summary) {
        todayTotal.value = summary.total;
        todayCompleted.value = summary.completed;
      },
    );
  }

  Future<void> _loadFlags() async {
    final result = await _getFlagsUsecase.call(limit: 100);
    result.fold(
      (failure) {},
      (data) {
        flags.value = data.items.where((f) => f.id.isNotEmpty).toList();
        flags.value.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      },
    );
  }

  Future<void> selectWeekday(int weekday) async {
    if (selectedWeekday.value == weekday) return;
    selectedWeekday.value = weekday;
    await loadRoutinesForWeekday(weekday);
  }

  Future<void> loadRoutinesForWeekday(int weekday) async {
    if (_routinesLoading) return;
    _routinesLoading = true;
    loading.value = true;
    try {
      final result = await _getRoutinesByWeekdayUsecase.call(weekday);

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
      loading.value = false;
      _routinesLoading = false;
    }
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
    createTitleController.text = '';
    createSelectedWeekdays.value = <int>{};
    createStartTime.value = '08:00';
    createEndTime.value = null;
    createRecurrenceType.value = 'weekly';
    createSelectedFlagId.value = null;
    error.value = null;
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
  }

  Future<bool> submitCreateRoutine() async {
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
    if (startTime.isEmpty) {
      error.value = 'Informe o horário da rotina.';
      return false;
    }

    return createRoutine(
      title: trimmed,
      weekdays: weekdays,
      startTime: startTime,
      endTime: createEndTime.value,
      recurrenceType: createRecurrenceType.value,
      flagId: createSelectedFlagId.value,
    );
  }

  Future<bool> createRoutine({
    required String title,
    required List<int> weekdays,
    required String startTime,
    String? endTime,
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

    if (startTime.isEmpty) {
      error.value = 'Informe o horário da rotina.';
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
        if (created.weekdays.contains(selectedWeekday.value)) {
          routines.value = [...routines.value, created];
          _groupRoutinesByPeriod();
        }
        return true;
      },
    );
  }

  Future<bool> completeRoutine(String routineId) async {
    final result = await _completeRoutineUsecase.call(routineId);

    return result.fold(
      (failure) {
        _setError(failure, fallback: 'Não foi possível concluir a rotina.');
        return false;
      },
      (_) {
        _completedRoutineIds.add(routineId);
        todayCompleted.value = todayCompleted.value + 1;
        return true;
      },
    );
  }

  Future<bool> uncompleteRoutine(String routineId) async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final result = await _uncompleteRoutineUsecase.call(routineId, dateStr);

    return result.fold(
      (failure) {
        _setError(failure, fallback: 'Não foi possível desmarcar a rotina.');
        return false;
      },
      (_) {
        _completedRoutineIds.remove(routineId);
        todayCompleted.value =
            (todayCompleted.value - 1).clamp(0, todayCompleted.value).toInt();
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
        routines.value = routines.value.where((r) => r.id != routineId).toList();
        _groupRoutinesByPeriod();
        return true;
      },
    );
  }

  bool isCompletedToday(String routineId) {
    return _completedRoutineIds.contains(routineId);
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

  void _setError(Failure failure, {required String fallback}) {
    final message = failure.message?.trim();
    if (message != null && message.isNotEmpty) {
      error.value = message;
    } else if (error.value == null || error.value!.isEmpty) {
      error.value = fallback;
    }
  }
}
