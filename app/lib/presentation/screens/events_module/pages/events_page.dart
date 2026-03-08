import 'package:flutter/material.dart';
import 'package:inbota/presentation/screens/events_module/components/event_calendar_strip.dart';
import 'package:inbota/presentation/screens/events_module/components/create_event_bottom_sheet.dart';
import 'package:inbota/presentation/screens/events_module/components/event_feed_item.dart';
import 'package:inbota/presentation/screens/events_module/components/event_filters.dart';
import 'package:inbota/presentation/screens/events_module/controller/events_controller.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/state/ib_state.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends IBState<EventsPage, EventsController> {
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
        controller.calendarDays,
        controller.selectedDate,
        controller.selectedFilter,
        controller.visibleItems,
      ]),
      builder: (context, _) {
        final loading = controller.loading.value;
        final days = controller.calendarDays.value;
        final selectedDate = controller.selectedDate.value;
        final selectedFilter = controller.selectedFilter.value;
        final items = controller.visibleItems.value;

        return ColoredBox(
          color: AppColors.background,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              EventCalendarStrip(
                days: days,
                selectedDate: selectedDate,
                months: controller.months,
                weekdays: controller.weekdays,
                onSelectDate: controller.selectDate,
              ),
              const SizedBox(height: 14),
              EventFilters(
                selected: selectedFilter,
                labelBuilder: controller.filterLabel,
                onSelect: controller.selectFilter,
              ),
              const SizedBox(height: 16),
              if (loading)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(child: IBLoader(label: 'Carregando agenda...')),
                )
              else if (items.isEmpty)
                const IBCard(
                  child: IBEmptyState(
                    title: 'Sem itens para este dia',
                    subtitle:
                        'Selecione outra data ou ajuste o filtro para ver mais resultados.',
                    icon: IBHugeIcon.calendar,
                  ),
                )
              else
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Dismissible(
                        key: ValueKey(
                          'event-item-${item.type.name}-${item.id}',
                        ),
                        direction: DismissDirection.endToStart,
                        background: const SizedBox.shrink(),
                        secondaryBackground: _buildDeleteBackground(),
                        confirmDismiss: (_) =>
                            controller.deleteVisibleItem(item),
                        child: IBItemCard(
                          title: item.title,
                          secondary: item.secondary,
                          done: item.done,
                          doneLabel: 'Feito',
                          typeLabel: _typeLabel(item.type),
                          typeColor: _typeColor(item.type),
                          typeIcon: _typeIcon(item.type),
                          timeLabel: _timeLabel(item),
                          timeIcon: item.allDay
                              ? IBIcon.eventAvailableOutlined
                              : IBIcon.alarmOutlined,
                          footer: _buildContextFooter(item),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
              IBText('Agenda', context: context).titulo.build(),
              const SizedBox(height: 6),
              IBText(
                'Eventos, tarefas e lembretes com data em um calendário único.',
                context: context,
              ).muted.build(),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Adicionar evento',
          onPressed: _openCreateEvent,
          icon: const IBIcon(
            IBIcon.addRounded,
            color: AppColors.primary700,
            size: 20,
          ),
        ),
      ],
    );
  }

  String _typeLabel(EventFeedItemType type) {
    switch (type) {
      case EventFeedItemType.event:
        return 'Evento';
      case EventFeedItemType.todo:
        return 'To-do';
      case EventFeedItemType.reminder:
        return 'Lembrete';
    }
  }

  Color _typeColor(EventFeedItemType type) {
    switch (type) {
      case EventFeedItemType.event:
        return AppColors.success600;
      case EventFeedItemType.todo:
        return AppColors.primary700;
      case EventFeedItemType.reminder:
        return AppColors.ai600;
    }
  }

  IconData _typeIcon(EventFeedItemType type) {
    switch (type) {
      case EventFeedItemType.event:
        return IBIcon.eventAvailableOutlined;
      case EventFeedItemType.todo:
        return IBIcon.taskAltRounded;
      case EventFeedItemType.reminder:
        return IBIcon.alarmOutlined;
    }
  }

  String _timeLabel(EventFeedItem item) {
    if (item.allDay) return 'Dia inteiro';
    if (!item.hasExplicitTime) return 'Sem horário';

    final startLabel = _formatHourMinute(item.date);
    if (item.hasExplicitEndTime && item.endDate != null) {
      return '$startLabel - ${_formatHourMinute(item.endDate!)}';
    }
    return startLabel;
  }

  String _formatHourMinute(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget? _buildContextFooter(EventFeedItem item) {
    final flag = item.flagLabel?.trim();
    final subflag = item.subflagLabel?.trim();

    final hasFlag = flag != null && flag.isNotEmpty;
    final hasSubflag = subflag != null && subflag.isNotEmpty;

    if (!hasFlag && !hasSubflag) return null;

    final chips = <Widget>[];
    if (hasFlag) {
      chips.add(
        IBTagChip(
          label: flag,
          color: _parseHexColor(item.flagColor, fallback: AppColors.primary700),
        ),
      );
    }
    if (hasSubflag) {
      chips.add(
        IBTagChip(
          label: subflag,
          color: _parseHexColor(
            item.subflagColor ?? item.flagColor,
            fallback: AppColors.ai600,
          ),
        ),
      );
    }

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
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

  Widget _buildDeleteBackground() {
    return ColoredBox(
      color: AppColors.background,
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: 84,
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.danger600,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: IBIcon(
              IBIcon.deleteOutlineRounded,
              color: AppColors.surface,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateEvent() async {
    if (!mounted) return;

    await IBBottomSheet.show<void>(
      context: context,
      isFitWithContent: true,
      child: CreateEventBottomSheet(
        loadingListenable: controller.loading,
        errorListenable: controller.error,
        flagsListenable: controller.flags,
        subflagsByFlagListenable: controller.subflagsByFlag,
        onLoadSubflags: controller.loadSubflags,
        onCreateEvent: controller.createEvent,
      ),
    );
  }
}
