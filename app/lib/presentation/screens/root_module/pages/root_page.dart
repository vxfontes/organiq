import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:organiq/presentation/routes/app_navigation.dart';
import 'package:organiq/presentation/routes/app_routes.dart';
import 'package:organiq/shared/components/oq_lib/index.dart';
import 'package:organiq/shared/services/analytics/screen_log_service.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _currentIndex = 0;
  late final ScreenLogService _screenLogService;

  @override
  void initState() {
    super.initState();
    _screenLogService = Modular.get<ScreenLogService>();
    _syncIndex();
    AppNavigation.addListener(_handleRouteChange);
    _ensureChildRoute();
  }

  @override
  void dispose() {
    AppNavigation.removeListener(_handleRouteChange);
    super.dispose();
  }

  void _handleRouteChange() {
    if (!mounted) return;
    _syncIndex();
  }

  void _syncIndex() {
    final nextIndex = _indexForPath(AppNavigation.path);
    if (nextIndex != _currentIndex) {
      setState(() => _currentIndex = nextIndex);
    }
  }

  void _ensureChildRoute() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final path = AppNavigation.path;
      if (path == AppRoutes.root || path == '${AppRoutes.root}/') {
        AppNavigation.navigate(AppRoutes.rootHome);
      }
    });
  }

  int _indexForPath(String path) {
    if (path.startsWith(AppRoutes.rootSchedule)) return 1;
    if (path.startsWith(AppRoutes.rootCreate)) return 2;
    if (path.startsWith(AppRoutes.rootShopping)) return 3;
    if (path.startsWith(AppRoutes.rootEvents)) return 4;
    return 0;
  }

  void _onNavTap(int index) {
    String targetRoute = AppRoutes.rootHome;
    switch (index) {
      case 0:
        targetRoute = AppRoutes.rootHome;
        break;
      case 1:
        targetRoute = AppRoutes.rootSchedule;
        break;
      case 2:
        targetRoute = AppRoutes.rootCreate;
        break;
      case 3:
        targetRoute = AppRoutes.rootShopping;
        break;
      case 4:
        targetRoute = AppRoutes.rootEvents;
        break;
    }
    _screenLogService.logInteraction(
      action: 'tap_bottom_nav',
      targetType: 'route',
      targetId: targetRoute,
      origin: 'root_bottom_nav',
      metadata: <String, dynamic>{'index': index},
    );
    AppNavigation.navigate(targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    return OQScaffold(
      appBar: OQAppBar(
        title: 'OrganiQ',
        padding: const EdgeInsets.only(left: 12, right: 12),
        actions: [
          IconButton(
            onPressed: () {
              _screenLogService.logInteraction(
                action: 'tap_notifications_history',
                targetType: 'route',
                targetId: AppRoutes.notificationHistory,
                origin: 'root_app_bar',
              );
              AppNavigation.push(AppRoutes.notificationHistory);
            },
            tooltip: 'Histórico de notificações',
            icon: const OQIcon(
              OQIcon.notificationsNoneOutlined,
              color: AppColors.surface,
              padding: EdgeInsets.all(0),
              size: 22,
            ),
          ),
          IconButton(
            onPressed: () {
              _screenLogService.logInteraction(
                action: 'tap_settings',
                targetType: 'route',
                targetId: AppRoutes.settings,
                origin: 'root_app_bar',
              );
              AppNavigation.push(AppRoutes.settings);
            },
            icon: const OQIcon(
              OQIcon.settingsOutlined,
              color: AppColors.surface,
              padding: EdgeInsets.all(0),
              size: 22,
            ),
          ),
        ],
      ),
      body: const RouterOutlet(),
      currentIndex: _currentIndex,
      onNavTap: _onNavTap,
      floatingActionButton: null,
    );
  }
}
