import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inbota/modules/notifications/data/models/notification_preferences_model.dart';
import 'package:inbota/presentation/screens/settings_module/controller/settings_notifications_controller.dart';
import 'package:inbota/shared/components/ib_lib/ib_chip_group.dart';
import 'package:inbota/shared/components/ib_lib/ib_toggle.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/services/push/push_notification_service.dart';
import 'package:inbota/shared/state/ib_state.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class SettingsNotificationsPage extends StatefulWidget {
  const SettingsNotificationsPage({super.key});

  @override
  State<SettingsNotificationsPage> createState() =>
      _SettingsNotificationsPageState();
}

class _SettingsNotificationsPageState
    extends
        IBState<SettingsNotificationsPage, SettingsNotificationsController> {
  @override
  void initState() {
    super.initState();
    controller.fetchPreferences();
    controller.error.addListener(_onErrorChanged);
    unawaited(PushNotificationService.instance.ensureTopic());
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
    return Scaffold(
      appBar: const IBLightAppBar(title: 'Notificações'),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([controller.loading, controller.prefs]),
          builder: (context, _) {
            final loading = controller.loading.value;
            final prefs = controller.prefs.value;

            if (prefs == null) {
              if (loading) {
                return const Center(child: IBLoader());
              }

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IBText(
                        'Não foi possível carregar as preferências.',
                        context: context,
                      ).muted.align(TextAlign.center).build(),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 210,
                        child: IBButton(
                          label: 'Tentar novamente',
                          variant: IBButtonVariant.secondary,
                          onPressed: () =>
                              unawaited(controller.fetchPreferences()),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: controller.fetchPreferences,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  if (loading) ...[
                    const LinearProgressIndicator(minHeight: 2),
                    const SizedBox(height: 14),
                  ],
                  _buildHeaderCard(context),
                  const SizedBox(height: 18),
                  _buildModuleSection(
                    context: context,
                    title: 'Lembretes',
                    subtitle:
                        'Avisos para não perder compromissos importantes.',
                    icon: IBIcon.stickyNote2Outlined,
                    enabled: prefs.remindersEnabled,
                    onEnabledChanged: (v) =>
                        _updatePrefs(prefs.copyWith(remindersEnabled: v)),
                    atTimeTitle: 'Na hora exata',
                    atTimeSubtitle: 'Envia aviso no horário do lembrete.',
                    atTimeValue: prefs.reminderAtTime,
                    onAtTimeChanged: (v) =>
                        _updatePrefs(prefs.copyWith(reminderAtTime: v)),
                    leadOptions: [
                      const IBChipOption(label: '5 min', value: 5),
                      const IBChipOption(label: '15 min', value: 15),
                      const IBChipOption(label: '30 min', value: 30),
                      const IBChipOption(label: '1 h', value: 60),
                    ],
                    selectedLeadMins: prefs.reminderLeadMins,
                    onLeadChanged: (v) =>
                        _updatePrefs(prefs.copyWith(reminderLeadMins: v)),
                  ),
                  const SizedBox(height: 16),
                  _buildModuleSection(
                    context: context,
                    title: 'Eventos',
                    subtitle: 'Notificações de encontros, reuniões e ocasiões.',
                    icon: IBIcon.eventAvailableOutlined,
                    enabled: prefs.eventsEnabled,
                    onEnabledChanged: (v) =>
                        _updatePrefs(prefs.copyWith(eventsEnabled: v)),
                    atTimeTitle: 'Na hora exata',
                    atTimeSubtitle: 'Notifica no horário de início do evento.',
                    atTimeValue: prefs.eventAtTime,
                    onAtTimeChanged: (v) =>
                        _updatePrefs(prefs.copyWith(eventAtTime: v)),
                    leadOptions: [
                      const IBChipOption(label: '15 min', value: 15),
                      const IBChipOption(label: '1 h', value: 60),
                      const IBChipOption(label: '1 dia', value: 1440),
                    ],
                    selectedLeadMins: prefs.eventLeadMins,
                    onLeadChanged: (v) =>
                        _updatePrefs(prefs.copyWith(eventLeadMins: v)),
                  ),
                  const SizedBox(height: 16),
                  _buildModuleSection(
                    context: context,
                    title: 'Tarefas',
                    subtitle:
                        'Lembretes de vencimento para manter o fluxo em dia.',
                    icon: IBIcon.taskAltRounded,
                    enabled: prefs.tasksEnabled,
                    onEnabledChanged: (v) =>
                        _updatePrefs(prefs.copyWith(tasksEnabled: v)),
                    atTimeTitle: 'Na hora do vencimento',
                    atTimeSubtitle: 'Notifica quando a tarefa expira.',
                    atTimeValue: prefs.taskAtTime,
                    onAtTimeChanged: (v) =>
                        _updatePrefs(prefs.copyWith(taskAtTime: v)),
                    leadOptions: [
                      const IBChipOption(label: '5 min', value: 5),
                      const IBChipOption(label: '15 min', value: 15),
                      const IBChipOption(label: '30 min', value: 30),
                      const IBChipOption(label: '1 h', value: 60),
                      const IBChipOption(label: '1 dia', value: 1440),
                    ],
                    selectedLeadMins: prefs.taskLeadMins,
                    onLeadChanged: (v) =>
                        _updatePrefs(prefs.copyWith(taskLeadMins: v)),
                  ),
                  const SizedBox(height: 16),
                  _buildModuleSection(
                    context: context,
                    title: 'Rotinas',
                    subtitle: 'Alertas para manter consistência nos hábitos.',
                    icon: IBIcon.repeatRounded,
                    enabled: prefs.routinesEnabled,
                    onEnabledChanged: (v) =>
                        _updatePrefs(prefs.copyWith(routinesEnabled: v)),
                    atTimeTitle: 'Na hora de início',
                    atTimeSubtitle: 'Envia no início da rotina.',
                    atTimeValue: prefs.routineAtTime,
                    onAtTimeChanged: (v) =>
                        _updatePrefs(prefs.copyWith(routineAtTime: v)),
                    leadOptions: [
                      const IBChipOption(label: '15 min', value: 15),
                    ],
                    selectedLeadMins: prefs.routineLeadMins,
                    onLeadChanged: (v) =>
                        _updatePrefs(prefs.copyWith(routineLeadMins: v)),
                  ),
                  const SizedBox(height: 16),
                  _buildQuietHoursSection(context, prefs),
                  const SizedBox(height: 16),
                  _buildDeviceSection(context),
                  const SizedBox(height: 24),
                  ValueListenableBuilder<bool>(
                    valueListenable: controller.sendingTest,
                    builder: (_, sending, _) {
                      return IBButton(
                        label: 'Enviar notificação de teste',
                        loading: sending,
                        onPressed: () async {
                          final success = await controller
                              .sendTestNotification();
                          if (success && mounted) {
                            IBSnackBar.success(
                              this.context,
                              'Notificação de teste enviada!',
                            );
                          }
                        },
                        variant: IBButtonVariant.secondary,
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return IBCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IBIcon(
            IBIcon.notificationsActiveRounded,
            size: 20,
            color: AppColors.primary700,
            backgroundColor: AppColors.surfaceSoft,
            borderColor: AppColors.primary200,
            padding: EdgeInsets.all(10),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IBText(
                  'Central de notificações',
                  context: context,
                ).subtitulo.build(),
                const SizedBox(height: 4),
                IBText(
                  'Escolha quais alertas receber, com qual antecedência e quando silenciar.',
                  context: context,
                ).caption.build(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleSection({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool enabled,
    required ValueChanged<bool> onEnabledChanged,
    required String atTimeTitle,
    required String atTimeSubtitle,
    required bool atTimeValue,
    required ValueChanged<bool> onAtTimeChanged,
    required List<IBChipOption<int>> leadOptions,
    required List<int> selectedLeadMins,
    required ValueChanged<List<int>> onLeadChanged,
  }) {
    return _Section(
      title: title,
      subtitle: subtitle,
      icon: icon,
      children: [
        IBToggle(
          title: 'Ativar notificações',
          subtitle: 'Controle principal deste módulo.',
          leadingIcon: IBIcon.notificationsActiveRounded,
          value: enabled,
          onChanged: onEnabledChanged,
        ),
        const SizedBox(height: 10),
        IBToggle(
          title: atTimeTitle,
          subtitle: atTimeSubtitle,
          leadingIcon: IBIcon.alarmOutlined,
          enabled: enabled,
          value: atTimeValue,
          onChanged: onAtTimeChanged,
        ),
        const SizedBox(height: 12),
        _buildLeadTimeSelector(
          context: context,
          enabled: enabled,
          options: leadOptions,
          selectedValues: selectedLeadMins,
          onChanged: onLeadChanged,
        ),
      ],
    );
  }

  Widget _buildLeadTimeSelector({
    required BuildContext context,
    required bool enabled,
    required List<IBChipOption<int>> options,
    required List<int> selectedValues,
    required ValueChanged<List<int>> onChanged,
  }) {
    final selectedLabels = options
        .where((option) => selectedValues.contains(option.value))
        .map((option) => option.label)
        .toList(growable: false);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: enabled ? AppColors.surface : AppColors.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IBText('Antecedência', context: context).label
                  .color(enabled ? AppColors.text : AppColors.textMuted)
                  .build(),
              const Spacer(),
              IBText(
                selectedLabels.isEmpty
                    ? 'Nenhuma selecionada'
                    : '${selectedLabels.length} selecionada(s)',
                context: context,
              ).caption.build(),
            ],
          ),
          if (selectedLabels.isNotEmpty) ...[
            const SizedBox(height: 4),
            IBText(
              selectedLabels.join(' • '),
              context: context,
            ).caption.build(),
          ],
          const SizedBox(height: 10),
          IBChipGroup<int>(
            options: options,
            enabled: enabled,
            selectedValues: selectedValues,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildQuietHoursSection(
    BuildContext context,
    NotificationPreferencesModel prefs,
  ) {
    return _Section(
      title: 'Horário de silêncio',
      subtitle: 'Evita notificações em períodos de descanso ou foco.',
      icon: IBIcon.stopCircleRounded,
      children: [
        IBToggle(
          title: 'Ativar silêncio',
          subtitle: 'Bloqueia alertas dentro do intervalo configurado.',
          leadingIcon: IBIcon.notificationsNoneOutlined,
          value: prefs.quietHoursEnabled,
          onChanged: (v) => _updatePrefs(prefs.copyWith(quietHoursEnabled: v)),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: prefs.quietHoursEnabled
              ? Row(
                  key: const ValueKey('quiet-hours-enabled'),
                  children: [
                    Expanded(
                      child: IBTimeField(
                        label: 'Das',
                        valueLabel: prefs.quietStart ?? '22:00',
                        enabled: true,
                        hasValue: true,
                        onTap: () => _pickQuietTime(true, prefs),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: IBTimeField(
                        label: 'Até',
                        valueLabel: prefs.quietEnd ?? '08:00',
                        enabled: true,
                        hasValue: true,
                        onTap: () => _pickQuietTime(false, prefs),
                      ),
                    ),
                  ],
                )
              : Container(
                  key: const ValueKey('quiet-hours-disabled'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: IBText(
                    'As notificações serão enviadas a qualquer hora enquanto essa opção estiver desativada.',
                    context: context,
                  ).caption.build(),
                ),
        ),
      ],
    );
  }

  Widget _buildDeviceSection(BuildContext context) {
    return _Section(
      title: 'Dispositivo (ntfy.sh)',
      subtitle:
          'Receba alertas com o app fechado usando o tópico do seu aparelho.',
      icon: IBIcon.notificationsNoneOutlined,
      children: [
        IBText(
          'Use este tópico no app ntfy para manter o recebimento de notificações em segundo plano.',
          context: context,
        ).caption.build(),
        const SizedBox(height: 12),
        ValueListenableBuilder<bool>(
          valueListenable:
              PushNotificationService.instance.topicLoadingListenable,
          builder: (context, loading, _) {
            return ValueListenableBuilder<String?>(
              valueListenable: PushNotificationService.instance.topicListenable,
              builder: (context, topic, __) {
                final topicLabel =
                    topic ??
                    (loading ? 'Gerando tópico...' : 'Tópico indisponível');

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const IBIcon(
                              IBIcon.notificationsNoneOutlined,
                              size: 16,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: IBText(
                                topicLabel,
                                context: context,
                              ).body.maxLines(2).build(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: topic == null
                          ? null
                          : () {
                              Clipboard.setData(ClipboardData(text: topic));
                              IBSnackBar.success(context, 'Tópico copiado!');
                            },
                      tooltip: 'Copiar tópico',
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceSoft,
                        foregroundColor: AppColors.primary700,
                        disabledForegroundColor: AppColors.textMuted,
                      ),
                    ),
                    IconButton(
                      onPressed: loading
                          ? null
                          : () => unawaited(
                              PushNotificationService.instance.ensureTopic(
                                forceRefresh: true,
                              ),
                            ),
                      tooltip: 'Gerar novamente',
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceSoft,
                        foregroundColor: AppColors.primary700,
                        disabledForegroundColor: AppColors.textMuted,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _updatePrefs(NotificationPreferencesModel newPrefs) {
    controller.updatePreferences(newPrefs);
  }

  Future<void> _pickQuietTime(
    bool isStart,
    NotificationPreferencesModel prefs,
  ) async {
    final initial = isStart ? prefs.quietStart : prefs.quietEnd;
    final time = await IBTimeField.pickTime(
      context,
      initialTime: initial != null
          ? _parseTime(initial)
          : (isStart
                ? const TimeOfDay(hour: 22, minute: 0)
                : const TimeOfDay(hour: 8, minute: 0)),
    );

    if (time != null) {
      final timeStr =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      if (isStart) {
        _updatePrefs(prefs.copyWith(quietStart: timeStr));
      } else {
        _updatePrefs(prefs.copyWith(quietEnd: timeStr));
      }
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IBIcon(
              icon,
              size: 18,
              color: AppColors.primary700,
              backgroundColor: AppColors.surfaceSoft,
              borderColor: AppColors.primary200,
              padding: const EdgeInsets.all(9),
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IBText(title, context: context).subtitulo.build(),
                  const SizedBox(height: 2),
                  IBText(subtitle, context: context).caption.build(),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        IBCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }
}
