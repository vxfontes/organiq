import 'package:flutter/material.dart';

import 'package:inbota/presentation/routes/app_navigation.dart';
import 'package:inbota/presentation/routes/app_routes.dart';
import 'package:inbota/presentation/screens/home_module/controller/home_controller.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';

class HomeWeekStripSection extends StatelessWidget {
  const HomeWeekStripSection({
    super.key,
    required this.controller,
    required this.selectedDate,
    this.onDayTap,
  });

  final HomeController controller;
  final DateTime selectedDate;
  final ValueChanged<DateTime>? onDayTap;

  @override
  Widget build(BuildContext context) {
    return IBWeekStrip(
      selectedDate: selectedDate,
      densityMap: controller.weekDensityMap,
      onDayTap: (day) {
        onDayTap?.call(day);
        AppNavigation.push(
          AppRoutes.rootEvents,
          args: {'selectedDate': day.toIso8601String()},
        );
      },
    );
  }
}
