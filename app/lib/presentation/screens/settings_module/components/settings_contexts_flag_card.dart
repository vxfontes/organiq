import 'package:flutter/material.dart';
import 'package:inbota/modules/flags/data/models/flag_output.dart';
import 'package:inbota/modules/flags/data/models/subflag_output.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class SettingsContextsFlagCard extends StatelessWidget {
  const SettingsContextsFlagCard({
    super.key,
    required this.flag,
    required this.subflags,
    required this.disabled,
    required this.parseColor,
    required this.onAddSubflag,
    required this.onEditFlag,
    required this.onDeleteFlag,
    required this.onEditSubflag,
    required this.onDeleteSubflag,
  });

  final FlagOutput flag;
  final List<SubflagOutput> subflags;
  final bool disabled;
  final Color Function(String? color) parseColor;
  final VoidCallback onAddSubflag;
  final VoidCallback onEditFlag;
  final VoidCallback onDeleteFlag;
  final ValueChanged<SubflagOutput> onEditSubflag;
  final ValueChanged<SubflagOutput> onDeleteSubflag;

  @override
  Widget build(BuildContext context) {
    return IBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: parseColor(flag.color),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IBText(
                      flag.name,
                      context: context,
                    ).subtitulo.maxLines(2).build(),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: IBText(
                        '${subflags.length} subflag(s)',
                        context: context,
                      ).caption.build(),
                    ),
                  ],
                ),
              ),
              _ActionIconButton(
                tooltip: 'Adicionar subflag',
                onPressed: disabled ? null : onAddSubflag,
                icon: IBIcon.addRounded,
                iconColor: AppColors.primary700,
                backgroundColor: AppColors.surfaceSoft,
              ),
              const SizedBox(width: 4),
              _ActionIconButton(
                tooltip: 'Editar flag',
                onPressed: disabled ? null : onEditFlag,
                icon: IBIcon.editOutlineRounded,
                iconColor: AppColors.textMuted,
                backgroundColor: AppColors.surfaceSoft,
              ),
              const SizedBox(width: 4),
              _ActionIconButton(
                tooltip: 'Excluir flag',
                onPressed: disabled ? null : onDeleteFlag,
                icon: IBIcon.deleteOutlineRounded,
                iconColor: AppColors.danger600,
                backgroundColor: AppColors.surfaceSoft,
              ),
            ],
          ),
          const SizedBox(height: 12),
          IBText('Subflags', context: context).caption.build(),
          const SizedBox(height: 8),
          if (subflags.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: IBText(
                'Sem subflags. Adicione para detalhar esse contexto.',
                context: context,
              ).muted.build(),
            ),
          if (subflags.isNotEmpty)
            ...subflags.expand(
              (item) => [
                _SubflagRow(
                  flag: flag,
                  subflag: item,
                  disabled: disabled,
                  parseColor: parseColor,
                  onEdit: () => onEditSubflag(item),
                  onDelete: () => onDeleteSubflag(item),
                ),
                const SizedBox(height: 8),
              ],
            ),
          const Divider(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: IBButton(
              label: 'Adicionar subflag',
              variant: IBButtonVariant.ghost,
              onPressed: disabled ? null : onAddSubflag,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubflagRow extends StatelessWidget {
  const _SubflagRow({
    required this.flag,
    required this.subflag,
    required this.disabled,
    required this.parseColor,
    required this.onEdit,
    required this.onDelete,
  });

  final FlagOutput flag;
  final SubflagOutput subflag;
  final bool disabled;
  final Color Function(String? color) parseColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: parseColor(subflag.color ?? flag.color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: IBText(
              subflag.name,
              context: context,
            ).body.maxLines(2).build(),
          ),
          _ActionIconButton(
            tooltip: 'Editar subflag',
            onPressed: disabled ? null : onEdit,
            icon: IBIcon.editOutlineRounded,
            iconColor: AppColors.textMuted,
            backgroundColor: AppColors.surface,
          ),
          const SizedBox(width: 4),
          _ActionIconButton(
            tooltip: 'Excluir subflag',
            onPressed: disabled ? null : onDelete,
            icon: IBIcon.deleteOutlineRounded,
            iconColor: AppColors.danger600,
            backgroundColor: AppColors.surface,
          ),
        ],
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: iconColor,
        disabledForegroundColor: AppColors.textMuted,
      ),
    );
  }
}
