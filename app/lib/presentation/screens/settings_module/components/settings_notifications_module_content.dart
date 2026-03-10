import 'package:flutter/material.dart';
import 'package:inbota/shared/components/ib_lib/ib_chip_group.dart';
import 'package:inbota/shared/components/ib_lib/ib_toggle.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/theme/app_colors.dart';
import 'package:inbota/shared/utils/text_utils.dart';

class SettingsNotificationsModuleContent extends StatelessWidget {
  const SettingsNotificationsModuleContent({
    super.key,
    required this.enabled,
    required this.onEnabledChanged,
    required this.atTimeTitle,
    required this.atTimeSubtitle,
    required this.atTimeValue,
    required this.onAtTimeChanged,
    required this.leadOptions,
    required this.selectedLeadMins,
    required this.onLeadChanged,
  });

  final bool enabled;
  final ValueChanged<bool> onEnabledChanged;
  final String atTimeTitle;
  final String atTimeSubtitle;
  final bool atTimeValue;
  final ValueChanged<bool> onAtTimeChanged;
  final List<IBChipOption<int>> leadOptions;
  final List<int> selectedLeadMins;
  final ValueChanged<List<int>> onLeadChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
        _LeadTimeSelector(
          enabled: enabled,
          options: leadOptions,
          selectedValues: selectedLeadMins,
          onChanged: onLeadChanged,
        ),
      ],
    );
  }
}

class _LeadTimeSelector extends StatelessWidget {
  const _LeadTimeSelector({
    required this.enabled,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
  });

  final bool enabled;
  final List<IBChipOption<int>> options;
  final List<int> selectedValues;
  final ValueChanged<List<int>> onChanged;

  @override
  Widget build(BuildContext context) {
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
                    : TextUtils.countLabel(
                        selectedLabels.length,
                        'selecionada',
                        'selecionadas',
                      ),
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
}
