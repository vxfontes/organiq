import 'package:flutter/material.dart';
import 'package:organiq/modules/home/data/models/home_greeting_style.dart';
import 'package:organiq/presentation/routes/app_navigation.dart';
import 'package:organiq/presentation/routes/app_routes.dart';
import 'package:organiq/shared/components/dynamic_header/afternoon_sky_painter.dart';
import 'package:organiq/shared/components/dynamic_header/morning_sky_painter.dart';
import 'package:organiq/shared/components/dynamic_header/night_sky_painter.dart';
import 'package:organiq/shared/components/oq_lib/index.dart';
import 'package:organiq/shared/theme/app_colors.dart';
import 'package:organiq/shared/utils/date_time.dart';
import 'package:organiq/shared/utils/text_utils.dart';

class HomeDynamicHeader extends StatelessWidget {
  const HomeDynamicHeader({super.key, this.userName});

  final String? userName;

  static final _morningSkyPainter = MorningSkyPainter();
  static final _afternoonSkyPainter = AfternoonSkyPainter();
  static final _nightSkyPainter = NightSkyPainter();

  @override
  Widget build(BuildContext context) {
    final now = DateTimeUtils.nowInUserTimezone();
    final greeting = _greetingForHour(now.hour);
    final greetingLabel = TextUtils.greetingWithOptionalName(
      greeting.label,
      name: userName,
    );

    return Container(
      height: 80,
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
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CustomPaint(painter: greeting.skyPainter),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OQText(
                      greetingLabel,
                      context: context,
                    ).subtitulo.color(greeting.textColor).build(),
                    const SizedBox(height: 4),
                    OQText(
                      _formatPtDate(now),
                      context: context,
                    ).caption.color(greeting.textColor).build(),
                  ],
                ),
                IconButton(
                  tooltip: 'Ver todos os lembretes',
                  onPressed: () => AppNavigation.push(AppRoutes.rootReminders),
                  icon: OQIcon(
                    OQIcon.alarmOutlined,
                    color: greeting.accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPtDate(DateTime date) {
    const weekdays = [
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
      'Domingo',
    ];
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

  GreetingStyle _greetingForHour(int hour) {
    if (hour >= 5 && hour < 12) {
      return GreetingStyle(
        label: 'Bom dia',
        accentColor: AppColors.warning500,
        textColor: AppColors.text,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.skyMorningTop, AppColors.skyMorningBottom],
        ),
        skyPainter: _morningSkyPainter,
      );
    } else if (hour >= 12 && hour < 18) {
      return GreetingStyle(
        label: 'Boa tarde',
        accentColor: AppColors.surface,
        textColor: AppColors.surface,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.skyAfternoonTop,
            AppColors.skyAfternoonMid,
            AppColors.skyAfternoonBottom,
          ],
        ),
        skyPainter: _afternoonSkyPainter,
      );
    } else {
      return GreetingStyle(
        label: 'Boa noite',
        accentColor: AppColors.starWhite,
        textColor: AppColors.surface,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.skyNightTop, AppColors.skyNightBottom],
        ),
        skyPainter: _nightSkyPainter,
      );
    }
  }
}
