import 'package:flutter/material.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';

class SettingsContextsEmptyStateCard extends StatelessWidget {
  const SettingsContextsEmptyStateCard({
    super.key,
    required this.disabled,
    required this.onCreateFlag,
  });

  final bool disabled;
  final VoidCallback onCreateFlag;

  @override
  Widget build(BuildContext context) {
    return IBCard(
      child: Column(
        children: [
          const IBEmptyState(
            title: 'Sem contextos ainda',
            subtitle:
                'Crie sua primeira flag para organizar tarefas e eventos.',
            icon: IBHugeIcon.home,
          ),
          const SizedBox(height: 14),
          IBButton(
            label: 'Criar primeira flag',
            onPressed: disabled ? null : onCreateFlag,
          ),
        ],
      ),
    );
  }
}
