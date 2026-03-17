import 'package:flutter/material.dart';

import 'package:organiq/presentation/routes/app_navigation.dart';
import 'package:organiq/presentation/routes/app_routes.dart';
import 'package:organiq/presentation/screens/home_module/controller/home_controller.dart';
import 'package:organiq/shared/components/oq_lib/index.dart';

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
    return OQWeekStrip(
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
