import 'package:flutter/material.dart';

import 'package:organiq/shared/components/oq_lib/index.dart';

class HomeEmptyState extends StatelessWidget {
  const HomeEmptyState({super.key, required this.onCreateTap});

  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return OQCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 4),
          const OQEmptyState(
            title: 'Seu dia esta livre!',
            subtitle: 'Aproveite o tempo ou adicione algo novo.',
            icon: OQHugeIcon.calendar,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OQButton(
              label: 'Criar com IA',
              onPressed: onCreateTap,
              variant: OQButtonVariant.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
