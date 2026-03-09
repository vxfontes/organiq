import 'package:flutter/material.dart';
import 'package:inbota/modules/notifications/data/models/notification_preferences_model.dart';
import 'package:inbota/shared/components/ib_lib/ib_chip_group.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';

enum SettingsNotificationsSection {
  reminders,
  events,
  tasks,
  routines,
  quietHours,
  dailyDigest,
  dailySummaryToken,
  device,
}

class SettingsNotificationsModuleDefinition {
  const SettingsNotificationsModuleDefinition({
    required this.section,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.atTimeTitle,
    required this.atTimeSubtitle,
    required this.leadOptions,
    required this.isEnabled,
    required this.atTimeValue,
    required this.selectedLeadMins,
    required this.updateEnabled,
    required this.updateAtTime,
    required this.updateLeadMins,
  });

  final SettingsNotificationsSection section;
  final String title;
  final String subtitle;
  final IconData icon;
  final String atTimeTitle;
  final String atTimeSubtitle;
  final List<IBChipOption<int>> leadOptions;

  final bool Function(NotificationPreferencesModel prefs) isEnabled;
  final bool Function(NotificationPreferencesModel prefs) atTimeValue;
  final List<int> Function(NotificationPreferencesModel prefs) selectedLeadMins;

  final NotificationPreferencesModel Function(
    NotificationPreferencesModel prefs,
    bool value,
  )
  updateEnabled;
  final NotificationPreferencesModel Function(
    NotificationPreferencesModel prefs,
    bool value,
  )
  updateAtTime;
  final NotificationPreferencesModel Function(
    NotificationPreferencesModel prefs,
    List<int> value,
  )
  updateLeadMins;
}

final List<SettingsNotificationsModuleDefinition>
settingsNotificationsModuleDefinitions = [
  SettingsNotificationsModuleDefinition(
    section: SettingsNotificationsSection.reminders,
    title: 'Lembretes',
    subtitle: 'Avisos para não perder compromissos importantes.',
    icon: IBIcon.stickyNote2Outlined,
    atTimeTitle: 'Na hora exata',
    atTimeSubtitle: 'Envia aviso no horário do lembrete.',
    leadOptions: const [
      IBChipOption(label: '5 min', value: 5),
      IBChipOption(label: '15 min', value: 15),
      IBChipOption(label: '30 min', value: 30),
      IBChipOption(label: '1 h', value: 60),
    ],
    isEnabled: (prefs) => prefs.remindersEnabled,
    atTimeValue: (prefs) => prefs.reminderAtTime,
    selectedLeadMins: (prefs) => prefs.reminderLeadMins,
    updateEnabled: (prefs, value) => prefs.copyWith(remindersEnabled: value),
    updateAtTime: (prefs, value) => prefs.copyWith(reminderAtTime: value),
    updateLeadMins: (prefs, value) => prefs.copyWith(reminderLeadMins: value),
  ),
  SettingsNotificationsModuleDefinition(
    section: SettingsNotificationsSection.events,
    title: 'Eventos',
    subtitle: 'Notificações de encontros, reuniões e ocasiões.',
    icon: IBIcon.eventAvailableOutlined,
    atTimeTitle: 'Na hora exata',
    atTimeSubtitle: 'Notifica no horário de início do evento.',
    leadOptions: const [
      IBChipOption(label: '15 min', value: 15),
      IBChipOption(label: '1 h', value: 60),
      IBChipOption(label: '1 dia', value: 1440),
    ],
    isEnabled: (prefs) => prefs.eventsEnabled,
    atTimeValue: (prefs) => prefs.eventAtTime,
    selectedLeadMins: (prefs) => prefs.eventLeadMins,
    updateEnabled: (prefs, value) => prefs.copyWith(eventsEnabled: value),
    updateAtTime: (prefs, value) => prefs.copyWith(eventAtTime: value),
    updateLeadMins: (prefs, value) => prefs.copyWith(eventLeadMins: value),
  ),
  SettingsNotificationsModuleDefinition(
    section: SettingsNotificationsSection.tasks,
    title: 'Tarefas',
    subtitle: 'Lembretes de vencimento para manter o fluxo em dia.',
    icon: IBIcon.taskAltRounded,
    atTimeTitle: 'Na hora do vencimento',
    atTimeSubtitle: 'Notifica quando a tarefa expira.',
    leadOptions: const [
      IBChipOption(label: '5 min', value: 5),
      IBChipOption(label: '15 min', value: 15),
      IBChipOption(label: '30 min', value: 30),
      IBChipOption(label: '1 h', value: 60),
      IBChipOption(label: '1 dia', value: 1440),
    ],
    isEnabled: (prefs) => prefs.tasksEnabled,
    atTimeValue: (prefs) => prefs.taskAtTime,
    selectedLeadMins: (prefs) => prefs.taskLeadMins,
    updateEnabled: (prefs, value) => prefs.copyWith(tasksEnabled: value),
    updateAtTime: (prefs, value) => prefs.copyWith(taskAtTime: value),
    updateLeadMins: (prefs, value) => prefs.copyWith(taskLeadMins: value),
  ),
  SettingsNotificationsModuleDefinition(
    section: SettingsNotificationsSection.routines,
    title: 'Rotinas',
    subtitle: 'Alertas para manter consistência nos hábitos.',
    icon: IBIcon.repeatRounded,
    atTimeTitle: 'Na hora de início',
    atTimeSubtitle: 'Envia no início da rotina.',
    leadOptions: const [IBChipOption(label: '15 min', value: 15)],
    isEnabled: (prefs) => prefs.routinesEnabled,
    atTimeValue: (prefs) => prefs.routineAtTime,
    selectedLeadMins: (prefs) => prefs.routineLeadMins,
    updateEnabled: (prefs, value) => prefs.copyWith(routinesEnabled: value),
    updateAtTime: (prefs, value) => prefs.copyWith(routineAtTime: value),
    updateLeadMins: (prefs, value) => prefs.copyWith(routineLeadMins: value),
  ),
];
