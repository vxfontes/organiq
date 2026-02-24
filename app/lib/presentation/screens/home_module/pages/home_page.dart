import 'package:flutter/material.dart';
import 'package:inbota/modules/shopping/data/models/shopping_list_output.dart';
import 'package:inbota/presentation/screens/home_module/controller/home_controller.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/state/ib_state.dart';
import 'package:inbota/shared/theme/app_colors.dart';
import 'package:inbota/shared/utils/home_format.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends IBState<HomePage, HomeController> {
  @override
  void initState() {
    super.initState();
    controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        controller.loading,
        controller.refreshing,
        controller.error,
        controller.agenda,
        controller.shoppingLists,
        controller.shoppingItemsByList,
      ]),
      builder: (context, _) {
        final loading = controller.loading.value;
        final refreshing = controller.refreshing.value;
        final error = controller.error.value;

        if (loading && !controller.hasContent) {
          return const ColoredBox(
            color: AppColors.background,
            child: Center(child: IBLoader(label: 'Carregando resumo...')),
          );
        }

        return ColoredBox(
          color: AppColors.background,
          child: RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                _buildHeader(context, refreshing),
                if (error != null && error.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildErrorBanner(context, error),
                ],
                const SizedBox(height: 16),
                _buildAgendaSnapshot(context),
                const SizedBox(height: 20),
                _buildOverviewSection(context),
                const SizedBox(height: 20),
                _buildTodoSection(),
                const SizedBox(height: 20),
                _buildEventsSection(context),
                const SizedBox(height: 20),
                _buildReminderSection(context),
                const SizedBox(height: 20),
                _buildShoppingSection(context),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool refreshing) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IBText('Resumo do dia', context: context).titulo.build(),
              const SizedBox(height: 6),
              IBText(
                HomeFormat.todayHeadline(),
                context: context,
              ).muted.build(),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Atualizar',
          onPressed: refreshing ? null : controller.refresh,
          icon: refreshing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded, color: AppColors.primary700),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.danger600.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.danger600.withAlpha((0.25 * 255).round()),
        ),
      ),
      child: Row(
        children: [
          const IBIcon(
            Icons.error_outline_rounded,
            color: AppColors.danger600,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: IBText(
              message,
              context: context,
            ).caption.color(AppColors.danger600).build(),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaSnapshot(BuildContext context) {
    final overdueColor = controller.totalOverdueCount > 0
        ? AppColors.danger600
        : AppColors.success600;

    return IBOverviewCard(
      title: 'Agenda de hoje',
      subtitle:
          '${controller.eventsTodayCount} evento(s), ${controller.remindersTodayCount} lembrete(s) e ${controller.openTasksCount} tarefa(s) aberta(s).',
      chips: [
        IBChip(
          label: 'Atrasos ${controller.totalOverdueCount}',
          color: overdueColor,
        ),
        IBChip(
          label: 'Compras ${controller.pendingShoppingItemsCount}',
          color: AppColors.warning500,
        ),
        IBChip(
          label: 'Semana ${controller.eventsThisWeekCount} eventos',
          color: AppColors.primary700,
        ),
      ],
    );
  }

  Widget _buildOverviewSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Visão geral'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Lembretes',
                value: '${controller.remindersTodayCount} hoje',
                subtitle: '${controller.remindersUpcomingCount} proximos',
                color: AppColors.primary700,
                icon: IBIcon.alarmOutlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Eventos',
                value: '${controller.eventsThisWeekCount} semana',
                subtitle: '${controller.eventsTodayCount} hoje',
                color: AppColors.success600,
                icon: IBIcon.eventAvailableOutlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Compras',
                value: '${controller.openShoppingListsCount} listas',
                subtitle: '${controller.pendingShoppingItemsCount} itens',
                color: AppColors.warning500,
                icon: IBIcon.shoppingBagOutlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Tarefas',
                value: '${controller.openTasksCount} abertas',
                subtitle: '${controller.overdueTasksCount} atrasadas',
                color: AppColors.primary600,
                icon: IBIcon.taskAltRounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodoSection() {
    final tasks = controller.criticalTasks;
    return IBTodoList(
      title: 'Prioridades',
      subtitle: '${controller.openTasksCount} tarefa(s) em aberto',
      emptyLabel: 'Sem tarefas pendentes no momento.',
      items: tasks
          .map(
            (task) => IBTodoItemData(
              id: task.id,
              title: task.title,
              subtitle: HomeFormat.taskSubtitle(task),
              done: task.isDone,
            ),
          )
          .toList(),
      onToggle: controller.toggleCriticalTaskAt,
    );
  }

  Widget _buildEventsSection(BuildContext context) {
    final events = controller.homeUpcomingEventsPreview;
    if (events.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Proximos eventos'),
          const SizedBox(height: 12),
          const IBCard(
            child: IBEmptyState(
              title: 'Sem eventos proximos',
              subtitle: 'Quando houver eventos agendados, eles aparecem aqui.',
              icon: IBHugeIcon.calendar,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Proximos eventos'),
        const SizedBox(height: 12),
        ...events.expand(
          (event) => [
            IBInboxItemCard(
              title: event.title,
              subtitle: HomeFormat.eventSubtitle(event),
              statusLabel: HomeFormat.eventStatus(event),
              statusColor: AppColors.success600,
              tags: [
                'Evento',
                if (event.location != null && event.location!.trim().isNotEmpty)
                  event.location!.trim(),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ]..removeLast(),
    );
  }

  Widget _buildReminderSection(BuildContext context) {
    final reminders = controller.homeUpcomingRemindersPreview;
    if (reminders.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Proximos lembretes'),
          const SizedBox(height: 12),
          const IBCard(
            child: IBEmptyState(
              title: 'Sem lembretes proximos',
              subtitle: 'Quando houver novos lembretes, eles aparecem aqui.',
              icon: IBHugeIcon.reminder,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Proximos lembretes'),
        const SizedBox(height: 12),
        IBCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < reminders.length; i++) ...[
                IBReminderRow(
                  title: reminders[i].title,
                  time: HomeFormat.relativeDateTimeLabel(reminders[i].remindAt),
                  color: HomeFormat.reminderColor(i),
                ),
                if (i != reminders.length - 1)
                  const Divider(height: 20, color: AppColors.border),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShoppingSection(BuildContext context) {
    final lists = controller.homeShoppingListsPreview;
    if (lists.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Compras em aberto'),
          const SizedBox(height: 12),
          const IBCard(
            child: IBEmptyState(
              title: 'Sem listas pendentes',
              subtitle: 'As listas de compras pendentes aparecem aqui.',
              icon: IBHugeIcon.shoppingBag,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Compras em aberto'),
        const SizedBox(height: 12),
        IBCard(
          child: Column(
            children: [
              for (var i = 0; i < lists.length; i++) ...[
                _buildShoppingRow(context, lists[i]),
                if (i != lists.length - 1)
                  const Divider(height: 18, color: AppColors.border),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShoppingRow(BuildContext context, ShoppingListOutput list) {
    final pending = controller.pendingItemsForList(list.id);
    return Row(
      children: [
        const IBIcon(
          IBIcon.shoppingBagOutlined,
          color: AppColors.warning500,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: IBText(
            list.title,
            context: context,
          ).body.weight(FontWeight.w600).build(),
        ),
        IBChip(
          label: '$pending pendente(s)',
          color: pending == 0 ? AppColors.success600 : AppColors.warning500,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return IBText(title, context: context).subtitulo.build();
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return IBStatCard(
      title: title,
      value: value,
      subtitle: subtitle,
      color: color,
      icon: icon,
    );
  }
}
