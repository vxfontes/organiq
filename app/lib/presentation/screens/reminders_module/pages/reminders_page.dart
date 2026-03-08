import 'package:flutter/material.dart';

import 'package:inbota/modules/reminders/data/models/reminder_output.dart';
import 'package:inbota/modules/tasks/data/models/task_output.dart';
import 'package:inbota/presentation/screens/reminders_module/components/create_reminder_bottom_sheet.dart';
import 'package:inbota/presentation/screens/reminders_module/components/create_todo_bottom_sheet.dart';
import 'package:inbota/presentation/screens/reminders_module/controller/reminders_controller.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/state/ib_state.dart';
import 'package:inbota/shared/theme/app_colors.dart';
import 'package:inbota/shared/utils/reminders_format.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends IBState<RemindersPage, RemindersController> {
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
      IBSnackBar.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        controller.loading,
        controller.visibleTasks,
        controller.reminders,
      ]),
      builder: (context, _) {
        final tasks = controller.visibleTasks.value;
        final reminders = controller.reminders.value;
        final loading = controller.loading.value;
        final showFullLoading = loading;
        final loadingLabel = tasks.isEmpty && reminders.isEmpty
            ? 'Carregando...'
            : 'Atualizando...';

        return Stack(
          children: [
            ColoredBox(
              color: AppColors.background,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  _buildTodoSection(context, tasks),
                  _buildTodaySection(context, reminders),
                  _buildUpcomingSection(context, reminders),
                ],
              ),
            ),
            if (showFullLoading)
              Positioned.fill(
                child: ColoredBox(
                  color: AppColors.background,
                  child: Center(child: IBLoader(label: loadingLabel)),
                ),
              ),
          ],
        );
      },
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
              IBText('Lembretes e tarefas', context: context).titulo.build(),
              const SizedBox(height: 6),
              IBText(
                'Priorize o que vence hoje e acompanhe os próximos dias.',
                context: context,
              ).muted.build(),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Adicionar lembrete',
          onPressed: _openCreateReminder,
          icon: const IBIcon(
            IBIcon.addRounded,
            color: AppColors.primary700,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildTodoSection(BuildContext context, List<TaskOutput> tasks) {
    return IBTodoList(
      title: 'Tarefas',
      action: IconButton(
        tooltip: 'Adicionar tarefa',
        onPressed: _openCreateTodo,
        icon: const IBIcon(
          IBIcon.addRounded,
          color: AppColors.primary700,
          size: 20,
        ),
      ),
      emptyLabel: 'Quando surgirem tarefas, elas vão aparecer aqui.',
      items: tasks
          .map(
            (task) => IBTodoItemData(
              id: task.id,
              title: task.title,
              subtitle: RemindersFormat.taskSubtitle(task),
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
        IBText(title, context: context).subtitulo.build(),
        const SizedBox(height: 12),
        if (items.isEmpty)
          IBText(fallback, context: context).muted.build()
        else
          IBCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  IBReminderRow(
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
    return IBDateField.pickDateTime(
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

    await IBBottomSheet.show<void>(
      smallBottomSheet: false,
      context: context,
      child: CreateTodoSheet(
        loadingListenable: controller.loading,
        errorListenable: controller.error,
        flagsListenable: controller.flags,
        onCreateTask: controller.createTask,
        pickTaskDate: _pickTaskDate,
        formatTaskDate: _formatTaskDate,
      ),
    );
  }

  Future<void> _openCreateReminder() async {
    if (!mounted) return;

    await IBBottomSheet.show<void>(
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
