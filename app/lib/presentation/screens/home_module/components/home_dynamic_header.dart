import 'package:flutter/material.dart';
import 'package:inbota/presentation/routes/app_navigation.dart';
import 'package:inbota/presentation/routes/app_routes.dart';

import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/theme/app_colors.dart';
import 'package:inbota/shared/utils/text_utils.dart';

class HomeDynamicHeader extends StatelessWidget {
  const HomeDynamicHeader({
    super.key,
    this.userName,
  });

  final String? userName;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = _greetingForHour(now.hour);
    final greetingLabel = TextUtils.greetingWithOptionalName(
      greeting.label,
      name: userName,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: greeting.gradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 16,
            offset: Offset(0, 6),
            color: Color(0x0A111827),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IBText(greetingLabel, context: context).subtitulo.build(),
              const SizedBox(height: 4),
              IBText(
                _formatPtDate(now),
                context: context,
              ).caption.color(AppColors.textMuted).build(),
            ],
          ),
          IconButton(
            tooltip: 'Ver todos os lembretes',
            onPressed: () => AppNavigation.push(AppRoutes.rootReminders),
            icon: IBIcon(IBIcon.alarmOutlined, color: greeting.accentColor),
          ),
        ],
      ),
    );
  }

  String _formatPtDate(DateTime date) {
    const weekdays = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
    const months = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$weekday, ${date.day} de $month';
  }

  _GreetingStyle _greetingForHour(int hour) {
    if (hour < 12) {
      return const _GreetingStyle(
        label: 'Bom dia',
        accentColor: AppColors.primary600,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.morningStart, AppColors.morningEnd],
        ),
      );
    }

    if (hour < 18) {
      return const _GreetingStyle(
        label: 'Boa tarde',
        accentColor: AppColors.warning500,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.afternoonStart, AppColors.afternoonEnd],
        ),
      );
    }

    return const _GreetingStyle(
      label: 'Boa noite',
      accentColor: AppColors.ai600,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.nightStart, AppColors.nightEnd],
      ),
    );
  }
}

class _GreetingStyle {
  const _GreetingStyle({
    required this.label,
    required this.gradient,
    required this.accentColor,
  });

  final String label;
  final LinearGradient gradient;
  final Color accentColor;
}
