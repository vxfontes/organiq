import 'dart:async';

import 'package:flutter/material.dart';
import 'package:organiq/modules/notifications/data/models/notification_preferences_model.dart';
import 'package:organiq/presentation/screens/settings_module/components/settings_accordion_section.dart';
import 'package:organiq/presentation/screens/settings_module/components/settings_notifications_header_card.dart';
import 'package:organiq/presentation/screens/settings_module/components/settings_notifications_module_definitions.dart';
import 'package:organiq/presentation/screens/settings_module/components/settings_notifications_module_content.dart';
import 'package:organiq/presentation/screens/settings_module/components/settings_notifications_quiet_hours_content.dart';
import 'package:organiq/presentation/screens/settings_module/components/settings_notifications_daily_digest_content.dart';
import 'package:organiq/presentation/screens/settings_module/components/settings_notifications_daily_summary_token_content.dart';
import 'package:organiq/presentation/screens/settings_module/components/settings_notifications_device_content.dart';
import 'package:organiq/presentation/screens/settings_module/controller/settings_notifications_controller.dart';
import 'package:organiq/shared/components/oq_lib/index.dart';
import 'package:organiq/shared/state/oq_state.dart';

class SettingsNotificationsPage extends StatefulWidget {
  const SettingsNotificationsPage({super.key});

  @override
  State<SettingsNotificationsPage> createState() =>
      _SettingsNotificationsPageState();
}

class _SettingsNotificationsPageState
    extends
        OQState<SettingsNotificationsPage, SettingsNotificationsController> {
  SettingsNotificationsSection? _expandedSection =
      SettingsNotificationsSection.reminders;

  @override
  void initState() {
    super.initState();
    controller.fetchPreferences();
    controller.fetchDailySummaryToken();
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

  bool _isExpanded(SettingsNotificationsSection section) =>
      _expandedSection == section;

  void _toggleSection(SettingsNotificationsSection section) {
    setState(() {
      _expandedSection = _expandedSection == section ? null : section;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OQLightAppBar(title: 'Notificações'),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([controller.loading, controller.prefs]),
          builder: (context, _) {
            final loading = controller.loading.value;
            final prefs = controller.prefs.value;

            if (prefs == null) {
              if (loading) {
                return const Center(child: OQLoader());
              }

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OQText(
                        'Não foi possível carregar as preferências.',
                        context: context,
                      ).muted.align(TextAlign.center).build(),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 210,
                        child: OQButton(
                          label: 'Tentar novamente',
                          variant: OQButtonVariant.secondary,
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
                  const SettingsNotificationsHeaderCard(),
                  const SizedBox(height: 12),
                  ..._buildModuleSections(prefs),
                  _buildQuietHoursSection(prefs),
                  _buildDailyDigestSection(prefs),
                  _buildDeviceSection(),
                  _buildDailySummaryTokenSection(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildModuleSections(NotificationPreferencesModel prefs) {
    final widgets = <Widget>[];
    for (var i = 0; i < settingsNotificationsModuleDefinitions.length; i++) {
      final definition = settingsNotificationsModuleDefinitions[i];
      widgets.add(_buildModuleSection(definition, prefs));
    }
    return widgets;
  }

  Widget _buildModuleSection(
    SettingsNotificationsModuleDefinition definition,
    NotificationPreferencesModel prefs,
  ) {
    final enabled = definition.isEnabled(prefs);
    final atTimeValue = definition.atTimeValue(prefs);
    final selectedLeadMins = definition.selectedLeadMins(prefs);

    return SettingsAccordionSection(
      title: definition.title,
      subtitle: definition.subtitle,
      collapsedSummary: _moduleCollapsedSummary(
        enabled: enabled,
        atTimeValue: atTimeValue,
        leadCount: selectedLeadMins.length,
      ),
      icon: definition.icon,
      isExpanded: _isExpanded(definition.section),
      onTap: () => _toggleSection(definition.section),
      child: SettingsNotificationsModuleContent(
        enabled: enabled,
        onEnabledChanged: (value) =>
            _updatePrefs(definition.updateEnabled(prefs, value)),
        atTimeTitle: definition.atTimeTitle,
        atTimeSubtitle: definition.atTimeSubtitle,
        atTimeValue: atTimeValue,
        onAtTimeChanged: (value) =>
            _updatePrefs(definition.updateAtTime(prefs, value)),
        leadOptions: definition.leadOptions,
        selectedLeadMins: selectedLeadMins,
        onLeadChanged: (value) =>
            _updatePrefs(definition.updateLeadMins(prefs, value)),
      ),
    );
  }

  Widget _buildQuietHoursSection(NotificationPreferencesModel prefs) {
    final quietSummary = prefs.quietHoursEnabled
        ? '${prefs.quietStart ?? '22:00'} às ${prefs.quietEnd ?? '08:00'}'
        : 'Desativado';

    return SettingsAccordionSection(
      title: 'Horário de silêncio',
      subtitle: 'Evita notificações em períodos de descanso ou foco.',
      collapsedSummary: quietSummary,
      icon: OQIcon.stopCircleRounded,
      isExpanded: _isExpanded(SettingsNotificationsSection.quietHours),
      onTap: () => _toggleSection(SettingsNotificationsSection.quietHours),
      child: SettingsNotificationsQuietHoursContent(
        prefs: prefs,
        onEnabledChanged: (v) =>
            _updatePrefs(prefs.copyWith(quietHoursEnabled: v)),
        onPickStart: () => _pickQuietTime(true, prefs),
        onPickEnd: () => _pickQuietTime(false, prefs),
      ),
    );
  }

  Widget _buildDailyDigestSection(NotificationPreferencesModel prefs) {
    final digestSummary = prefs.dailyDigestEnabled
        ? 'Ativado para às ${prefs.dailyDigestHour.toString().padLeft(2, '0')}:00'
        : 'Desativado';

    return SettingsAccordionSection(
      title: 'Resumo Diário',
      subtitle: 'Resumo diário por e-mail com sua agenda.',
      collapsedSummary: digestSummary,
      icon: OQIcon.mailOutlineRounded,
      isExpanded: _isExpanded(SettingsNotificationsSection.dailyDigest),
      onTap: () => _toggleSection(SettingsNotificationsSection.dailyDigest),
      child: ValueListenableBuilder<bool>(
        valueListenable: controller.sendingEmailTest,
        builder: (context, sending, _) {
          return SettingsNotificationsDailyDigestContent(
            prefs: prefs,
            onEnabledChanged: (v) =>
                _updatePrefs(prefs.copyWith(dailyDigestEnabled: v)),
            onPickHour: () => _pickDigestHour(prefs),
            onSendTest: () async {
              final success = await controller.sendTestEmailDigest();
              if (success && mounted) {
                OQSnackBar.success(this.context, 'E-mail de teste enviado!');
              }
            },
            sendingTest: sending,
          );
        },
      ),
    );
  }

  Widget _buildDailySummaryTokenSection() {
    return SettingsAccordionSection(
      title: 'Resumo Diario API',
      subtitle: 'Token de acesso para seu resumo diário via API.',
      collapsedSummary: 'Copiar/rotacionar token',
      icon: OQIcon.keyRounded,
      isExpanded: _isExpanded(SettingsNotificationsSection.dailySummaryToken),
      onTap: () =>
          _toggleSection(SettingsNotificationsSection.dailySummaryToken),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          controller.dailySummaryToken,
          controller.dailySummaryUrl,
          controller.loadingDailySummaryToken,
        ]),
        builder: (context, _) {
          return SettingsNotificationsDailySummaryTokenContent(
            token: controller.dailySummaryToken.value,
            url: controller.dailySummaryUrl.value,
            loading: controller.loadingDailySummaryToken.value,
            onRefresh: () => unawaited(controller.fetchDailySummaryToken()),
            onRotate: controller.rotateDailySummaryToken,
          );
        },
      ),
    );
  }

  Widget _buildDeviceSection() {
    return SettingsAccordionSection(
      title: 'Dispositivo',
      subtitle: 'Sincronização e teste de push deste aparelho.',
      collapsedSummary: 'Sincronizar e enviar teste',
      icon: OQIcon.notificationsActiveRounded,
      isExpanded: _isExpanded(SettingsNotificationsSection.device),
      onTap: () => _toggleSection(SettingsNotificationsSection.device),
      child: ValueListenableBuilder<bool>(
        valueListenable: controller.sendingTest,
        builder: (context, sending, _) {
          return SettingsNotificationsDeviceContent(
            onSendTest: () async {
              final success = await controller.sendTestNotification();
              if (success && mounted) {
                OQSnackBar.success(
                  this.context,
                  'Notificação de teste enviada!',
                );
              }
            },
            sendingTest: sending,
          );
        },
      ),
    );
  }

  String _moduleCollapsedSummary({
    required bool enabled,
    required bool atTimeValue,
    required int leadCount,
  }) {
    if (!enabled) return 'Desativado';

    final leadLabel = leadCount == 1 ? 'antecedência' : 'antecedências';
    final leadSummary = leadCount == 0
        ? 'sem antecedência'
        : '$leadCount $leadLabel';

    return atTimeValue
        ? 'Ativo • Horário exato + $leadSummary'
        : 'Ativo • $leadSummary';
  }

  void _updatePrefs(NotificationPreferencesModel newPrefs) {
    controller.updatePreferences(newPrefs);
  }

  Future<void> _pickDigestHour(NotificationPreferencesModel prefs) async {
    final time = await OQTimeField.pickTime(
      context,
      initialTime: TimeOfDay(hour: prefs.dailyDigestHour, minute: 0),
    );

    if (time != null) {
      _updatePrefs(prefs.copyWith(dailyDigestHour: time.hour));
    }
  }

  Future<void> _pickQuietTime(
    bool isStart,
    NotificationPreferencesModel prefs,
  ) async {
    final initial = isStart ? prefs.quietStart : prefs.quietEnd;
    final time = await OQTimeField.pickTime(
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
