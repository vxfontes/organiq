import 'package:flutter/material.dart';

import 'package:organiq/modules/reminders/data/models/reminder_output.dart';
import 'package:organiq/modules/tasks/data/models/task_output.dart';
import 'package:organiq/presentation/screens/reminders_module/components/create_reminder_bottom_sheet.dart';
import 'package:organiq/presentation/screens/reminders_module/components/create_todo_bottom_sheet.dart';
import 'package:organiq/presentation/screens/reminders_module/controller/reminders_controller.dart';
import 'package:organiq/shared/components/oq_lib/index.dart';
import 'package:organiq/shared/state/oq_state.dart';
import 'package:organiq/shared/theme/app_colors.dart';
import 'package:organiq/shared/utils/reminders_format.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends OQState<RemindersPage, RemindersController> {
  @override
  void initState() {
    super.initState();
    controller.load();
    controller.error.addListener(_onErrorChanged);
  }

  @override
  void dispose() {
    controller.error.removeListener(_onErrorChanged);
    super.dispose();
  }

  void _onErrorChanged() {
    final error = controller.error.value;
    if (error != null && error.isNotEmpty && mounted) {
      OQSnackBar.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        controller.loading,
        controller.hasLoadedOnce,
        controller.visibleTasks,
        controller.reminders,
      ]),
      builder: (context, _) {
        final tasks = controller.visibleTasks.value;
        final reminders = controller.reminders.value;
        final loading = controller.loading.value;
        final hasLoadedOnce = controller.hasLoadedOnce.value;
        final showInitialLoading = !hasLoadedOnce;
        final showRefreshing = loading && hasLoadedOnce;

        return ColoredBox(
          color: AppColors.background,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              if (showRefreshing) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: const LinearProgressIndicator(minHeight: 3),
                ),
                const SizedBox(height: 16),
              ],
              if (showInitialLoading)
                _buildLoadingSkeleton()
              else ...[
                _buildTodoSection(context, tasks),
                _buildTodaySection(context, reminders),
                _buildUpcomingSection(context, reminders),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return const Column(
      children: [
        OQCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OQSkeleton(height: 18, width: 120),
              SizedBox(height: 14),
              OQSkeleton(height: 14, width: double.infinity),
              SizedBox(height: 10),
              OQSkeleton(height: 14, width: 200),
            ],
          ),
        ),
        SizedBox(height: 18),
        OQCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OQSkeleton(height: 16, width: 96),
              SizedBox(height: 12),
              OQSkeleton(height: 12, width: double.infinity),
              SizedBox(height: 8),
              OQSkeleton(height: 12, width: 180),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OQText('Lembretes e tarefas', context: context).titulo.build(),
              const SizedBox(height: 6),
              OQText(
                'Priorize o que vence hoje e acompanhe os próximos dias.',
                context: context,
              ).muted.build(),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Adicionar lembrete',
          onPressed: _openCreateReminder,
          icon: const OQIcon(
            OQIcon.addRounded,
            color: AppColors.primary700,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildTodoSection(BuildContext context, List<TaskOutput> tasks) {
    return OQTodoList(
      title: 'Tarefas',
      action: IconButton(
        tooltip: 'Adicionar tarefa',
        onPressed: _openCreateTodo,
        icon: const OQIcon(
          OQIcon.addRounded,
          color: AppColors.primary700,
          size: 20,
        ),
      ),
      emptyLabel: 'Quando surgirem tarefas, elas vão aparecer aqui.',
      items: tasks
          .map(
            (task) => OQTodoItemData(
              id: task.id,
              title: task.title,
              subtitle: RemindersFormat.taskSubtitle(task),
              subtitleTagLabel: _normalize(task.subflagName),
              subtitleTagColor: _parseHexColor(
                task.subflagColor ?? task.flagColor,
                fallback: AppColors.ai600,
              ),
              done: task.isDone,
            ),
          )
          .toList(),
      onToggle: (index, done) {
        controller.toggleVisibleTaskAt(index, done);
      },
      onDelete: controller.deleteVisibleTaskAt,
    );
  }

  Widget _buildTodaySection(
    BuildContext context,
    List<ReminderOutput> reminders,
  ) {
    final items = _todayReminders(
      reminders.where((item) => !item.isDone).toList(),
    );
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return _buildReminderSection(
      context,
      title: 'Hoje',
      items: items,
      fallback: 'Nenhum lembrete para hoje.',
    );
  }

  Widget _buildUpcomingSection(
    BuildContext context,
    List<ReminderOutput> reminders,
  ) {
    final items = _upcomingReminders(
      reminders.where((item) => !item.isDone).toList(),
    );
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return _buildReminderSection(
      context,
      title: 'Próximos dias',
      items: items,
      fallback: 'Sem lembretes programados.',
    );
  }

  Widget _buildReminderSection(
    BuildContext context, {
    required String title,
    required List<ReminderOutput> items,
    required String fallback,
    bool muted = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (items.isNotEmpty) const SizedBox(height: 24),
        OQText(title, context: context).subtitulo.build(),
        const SizedBox(height: 12),
        if (items.isEmpty)
          OQText(fallback, context: context).muted.build()
        else
          OQCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  OQReminderRow(
                    title: items[i].title,
                    time: RemindersFormat.formatReminderTime(items[i]),
                    color: muted
                        ? AppColors.textMuted
                        : _reminderColor(title, i),
                  ),
                  if (i != items.length - 1)
                    const Divider(height: 20, color: AppColors.border),
                ],
              ],
            ),
          ),
      ],
    );
  }

  List<ReminderOutput> _todayReminders(List<ReminderOutput> reminders) {
    final now = DateTime.now();
    return reminders
        .where(
          (item) =>
              item.remindAt != null &&
              RemindersFormat.isSameDay(item.remindAt!, now),
        )
        .toList();
  }

  List<ReminderOutput> _upcomingReminders(List<ReminderOutput> reminders) {
    final now = DateTime.now();
    final limit = now.add(const Duration(days: 7));
    return reminders
        .where(
          (item) =>
              item.remindAt == null ||
              (RemindersFormat.isAfterDay(item.remindAt!, now) &&
                  item.remindAt!.isBefore(limit)),
        )
        .toList();
  }

  Color _reminderColor(String section, int index) {
    if (section == 'Hoje') return AppColors.primary700;
    if (section == 'Próximos dias') return AppColors.ai600;
    return index.isEven ? AppColors.warning500 : AppColors.success600;
  }

  Future<DateTime?> _pickTaskDate(
    BuildContext context,
    DateTime? current,
  ) async {
    return OQDateField.pickDateTime(
      context,
      current: current,
      helpText: 'Selecionar data',
    );
  }

  String _formatTaskDate(DateTime? date) {
    if (date == null) return 'Sem data definida';
    final day = RemindersFormat.formatDate(date);
    if (date.hour == 0 && date.minute == 0) return day;
    final hour = RemindersFormat.formatHour(date);
    return '$day às $hour';
  }

  Future<void> _openCreateTodo() async {
    if (!mounted) return;

    await OQBottomSheet.show<void>(
      smallBottomSheet: false,
      context: context,
      child: CreateTodoSheet(
        loadingListenable: controller.loading,
        errorListenable: controller.error,
        flagsListenable: controller.flags,
        subflagsByFlagListenable: controller.subflagsByFlag,
        onLoadSubflags: controller.loadSubflags,
        onCreateTask: controller.createTask,
        pickTaskDate: _pickTaskDate,
        formatTaskDate: _formatTaskDate,
      ),
    );
  }

  String? _normalize(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  Color _parseHexColor(String? value, {required Color fallback}) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return fallback;

    var hex = raw.toUpperCase().replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return fallback;

    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) return fallback;
    return Color(parsed);
  }

  Future<void> _openCreateReminder() async {
    if (!mounted) return;

    await OQBottomSheet.show<void>(
      context: context,
      isFitWithContent: true,
      child: CreateReminderBottomSheet(
        loadingListenable: controller.loading,
        errorListenable: controller.error,
        flagsListenable: controller.flags,
        subflagsByFlagListenable: controller.subflagsByFlag,
        onLoadSubflags: controller.loadSubflags,
        onCreateReminder: controller.createReminder,
      ),
    );
  }
}
