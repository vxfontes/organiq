import 'package:flutter/material.dart';
import 'package:organiq/shared/components/oq_lib/index.dart';

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
    return OQCard(
      child: Column(
        children: [
          const OQEmptyState(
            title: 'Sem contextos ainda',
            subtitle:
                'Crie sua primeira flag para organizar tarefas e eventos.',
            icon: OQHugeIcon.home,
          ),
          const SizedBox(height: 14),
          OQButton(
            label: 'Criar primeira flag',
            onPressed: disabled ? null : onCreateFlag,
          ),
        ],
      ),
    );
  }
}
