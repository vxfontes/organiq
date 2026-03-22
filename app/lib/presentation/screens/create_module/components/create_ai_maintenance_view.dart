import 'package:flutter/material.dart';
import 'package:organiq/presentation/screens/create_module/components/create_mode_selector.dart';
import 'package:organiq/presentation/screens/create_module/components/create_page_header.dart';
import 'package:organiq/shared/components/oq_lib/index.dart';

class CreateAIMaintenanceView extends StatelessWidget {
  const CreateAIMaintenanceView({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.createAiEnabled,
    required this.suggestionAiEnabled,
    this.selectorEnabled = true,
  });

  final int mode;
  final ValueChanged<int> onModeChanged;
  final bool createAiEnabled;
  final bool suggestionAiEnabled;
  final bool selectorEnabled;

  String get _modeLabel => mode == 1 ? 'Sugerir' : 'Criar';

  @override
  Widget build(BuildContext context) {
    final hasFallbackMode = mode == 1 ? createAiEnabled : suggestionAiEnabled;
    final fallbackMode = mode == 1 ? 0 : 1;
    final fallbackLabel = mode == 1 ? 'Ir para Criar' : 'Ir para Sugerir';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        const CreatePageHeader(
          subtitle: 'Escolha entre Criar e Sugerir para organizar seu dia.',
        ),
        const SizedBox(height: 14),
        CreateModeSelector(
          mode: mode,
          onModeChanged: onModeChanged,
          enabled: selectorEnabled,
        ),
        const SizedBox(height: 20),
        OQCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
            child: OQEmptyState(
              title: '$_modeLabel em manutenção',
              subtitle:
                  'Desativamos temporariamente esta IA para estabilização. Tente novamente em alguns minutos.',
            ),
          ),
        ),
        if (hasFallbackMode) ...[
          const SizedBox(height: 12),
          OQButton(
            label: fallbackLabel,
            variant: OQButtonVariant.secondary,
            onPressed: selectorEnabled
                ? () => onModeChanged(fallbackMode)
                : null,
          ),
        ],
      ],
    );
  }
}
