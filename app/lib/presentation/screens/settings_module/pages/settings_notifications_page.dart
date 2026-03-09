import 'package:flutter/material.dart';
import 'package:inbota/modules/notifications/data/models/notification_preferences_model.dart';
import 'package:inbota/presentation/screens/settings_module/controller/settings_notifications_controller.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/components/ib_lib/ib_chip_group.dart';
import 'package:inbota/shared/components/ib_lib/ib_toggle.dart';
import 'package:inbota/shared/state/ib_state.dart';

class SettingsNotificationsPage extends StatefulWidget {
  const SettingsNotificationsPage({super.key});

  @override
  State<SettingsNotificationsPage> createState() => _SettingsNotificationsPageState();
}

class _SettingsNotificationsPageState extends IBState<SettingsNotificationsPage, SettingsNotificationsController> {
  @override
  void initState() {
    super.initState();
    controller.fetchPreferences();
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
    return Scaffold(
      appBar: const IBLightAppBar(title: 'Notificações'),
      body: SafeArea(
        child: ValueListenableBuilder<NotificationPreferencesModel?>(
          valueListenable: controller.prefs,
          builder: (context, prefs, _) {
            if (prefs == null) {
              return const Center(child: IBLoader());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Section(
                    title: 'Lembretes',
                    children: [
                      IBToggle(
                        title: 'Ativar notifications',
                        value: prefs.remindersEnabled,
                        onChanged: (v) => _updatePrefs(prefs.copyWith(remindersEnabled: v)),
                      ),
                      IBToggle(
                        title: 'Na hora exata',
                        value: prefs.reminderAtTime,
                        onChanged: (v) => _updatePrefs(prefs.copyWith(reminderAtTime: v)),
                      ),
                      const SizedBox(height: 8),
                      IBText('Antecedência', context: context).caption.build(),
                      const SizedBox(height: 8),
                      IBChipGroup<int>(
                        options: [
                          IBChipOption(label: '5min', value: 5),
                          IBChipOption(label: '15min', value: 15),
                          IBChipOption(label: '30min', value: 30),
                          IBChipOption(label: '1h', value: 60),
                        ],
                        selectedValues: prefs.reminderLeadMins,
                        onChanged: (v) => _updatePrefs(prefs.copyWith(reminderLeadMins: v)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _Section(
                    title: 'Eventos',
                    children: [
                      IBToggle(
                        title: 'Ativar notificações',
                        value: prefs.eventsEnabled,
                        onChanged: (v) => _updatePrefs(prefs.copyWith(eventsEnabled: v)),
                      ),
                      IBToggle(
                        title: 'Na hora exata',
                        value: prefs.eventAtTime,
                        onChanged: (v) => _updatePrefs(prefs.copyWith(eventAtTime: v)),
                      ),
                      const SizedBox(height: 8),
                      IBText('Antecedência', context: context).caption.build(),
                      const SizedBox(height: 8),
                      IBChipGroup<int>(
                        options: [
                          IBChipOption(label: '15min', value: 15),
                          IBChipOption(label: '1h', value: 60),
                          IBChipOption(label: '1dia', value: 1440),
                        ],
                        selectedValues: prefs.eventLeadMins,
                        onChanged: (v) => _updatePrefs(prefs.copyWith(eventLeadMins: v)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _Section(
                    title: 'Tarefas',
                    children: [
                      IBToggle(
                        title: 'Ativar notificações',
                        value: prefs.tasksEnabled,
                        onChanged: (v) => _updatePrefs(prefs.copyWith(tasksEnabled: v)),
                      ),
                      IBToggle(
                        title: 'Na hora do vencimento',
                        value: prefs.taskAtTime,
                        onChanged: (v) => _updatePrefs(prefs.copyWith(taskAtTime: v)),
                      ),
                      const SizedBox(height: 8),
                      IBText('Antecedência', context: context).caption.build(),
                      const SizedBox(height: 8),
                      IBChipGroup<int>(
                        options: [
                          IBChipOption(label: '1h', value: 60),
                          IBChipOption(label: '1dia', value: 1440),
                        ],
                        selectedValues: prefs.taskLeadMins,
                        onChanged: (v) => _updatePrefs(prefs.copyWith(taskLeadMins: v)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _Section(
                    title: 'Rotinas',
                    children: [
                      IBToggle(
                        title: 'Ativar notificações',
                        value: prefs.routinesEnabled,
                        onChanged: (v) => _updatePrefs(prefs.copyWith(routinesEnabled: v)),
                      ),
                      IBToggle(
                        title: 'Na hora de início',
                        value: prefs.routineAtTime,
                        onChanged: (v) => _updatePrefs(prefs.copyWith(routineAtTime: v)),
                      ),
                      const SizedBox(height: 8),
                      IBText('Antecedência', context: context).caption.build(),
                      const SizedBox(height: 8),
                      IBChipGroup<int>(
                        options: [
                          IBChipOption(label: '15min', value: 15),
                        ],
                        selectedValues: prefs.routineLeadMins,
                        onChanged: (v) => _updatePrefs(prefs.copyWith(routineLeadMins: v)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _Section(
                    title: 'Horário de silêncio',
                    children: [
                      IBToggle(
                        title: 'Ativar silêncio',
                        value: prefs.quietHoursEnabled,
                        onChanged: (v) => _updatePrefs(prefs.copyWith(quietHoursEnabled: v)),
                      ),
                      if (prefs.quietHoursEnabled) ...[
                        const SizedBox(height: 12),
                        Row(
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
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 32),
                  ValueListenableBuilder<bool>(
                    valueListenable: controller.sendingTest,
                    builder: (context, sending, _) {
                      return IBButton(
                        label: 'Enviar notificação de teste',
                        loading: sending,
                        onPressed: () async {
                          final success = await controller.sendTestNotification();
                          if (success && mounted) {
                            IBSnackBar.success(context, 'Notificação de teste enviada!');
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

  void _updatePrefs(NotificationPreferencesModel newPrefs) {
    controller.updatePreferences(newPrefs);
  }

  Future<void> _pickQuietTime(bool isStart, NotificationPreferencesModel prefs) async {
    final initial = isStart ? prefs.quietStart : prefs.quietEnd;
    final time = await IBTimeField.pickTime(
      context,
      initialTime: initial != null ? _parseTime(initial) : (isStart ? const TimeOfDay(hour: 22, minute: 0) : const TimeOfDay(hour: 8, minute: 0)),
    );

    if (time != null) {
      final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IBText(title, context: context).subtitulo.build(),
        const SizedBox(height: 12),
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
