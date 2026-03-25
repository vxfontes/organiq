import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:organiq/shared/services/analytics/app_error_log_service.dart';
import 'package:organiq/shared/services/analytics/app_session_service.dart';
import 'package:organiq/shared/services/analytics/screen_log_service.dart';

import '../shared/theme/app_theme.dart';

class AppWidget extends StatefulWidget {
  const AppWidget({super.key});

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> {
  late final AppSessionService _appSessionService;
  late final AppErrorLogService _appErrorLogService;
  late final ScreenLogService _screenLogService;

  @override
  void initState() {
    super.initState();
    _appSessionService = Modular.get<AppSessionService>();
    _appErrorLogService = Modular.get<AppErrorLogService>();
    _screenLogService = Modular.get<ScreenLogService>();
    _appSessionService.start();
    _appErrorLogService.start();
    _screenLogService.start();
  }

  @override
  void dispose() {
    _appErrorLogService.dispose();
    _screenLogService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Organiq',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: Modular.routerConfig,
    );
  }
}
