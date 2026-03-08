import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:inbota/presentation/routes/app_navigation.dart';
import 'package:inbota/presentation/routes/app_routes.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
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
    switch (index) {
      case 0:
        AppNavigation.navigate(AppRoutes.rootHome);
        break;
      case 1:
        AppNavigation.navigate(AppRoutes.rootSchedule);
        break;
      case 2:
        AppNavigation.navigate(AppRoutes.rootCreate);
        break;
      case 3:
        AppNavigation.navigate(AppRoutes.rootShopping);
        break;
      case 4:
        AppNavigation.navigate(AppRoutes.rootEvents);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IBScaffold(
      appBar: IBAppBar(
        title: 'Inbota',
        padding: const EdgeInsets.only(left: 12, right: 12),
        actions: [
          IconButton(
            onPressed: () => AppNavigation.push(AppRoutes.settings),
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedSettings01,
              color: AppColors.surface,
              size: 22,
              strokeWidth: 1.8,
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
