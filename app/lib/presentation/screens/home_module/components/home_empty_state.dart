import 'package:flutter/material.dart';

import 'package:inbota/shared/components/ib_lib/index.dart';

class HomeEmptyState extends StatelessWidget {
  const HomeEmptyState({super.key, required this.onCreateTap});

  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return IBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 4),
          const IBEmptyState(
            title: 'Seu dia esta livre!',
            subtitle: 'Aproveite o tempo ou adicione algo novo.',
            icon: IBHugeIcon.calendar,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: IBButton(
              label: 'Criar com IA',
              onPressed: onCreateTap,
              variant: IBButtonVariant.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
