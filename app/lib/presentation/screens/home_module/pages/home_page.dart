import 'package:flutter/material.dart';

import 'package:inbota/presentation/routes/app_navigation.dart';
import 'package:inbota/presentation/routes/app_routes.dart';
import 'package:inbota/presentation/screens/home_module/components/index.dart';
import 'package:inbota/presentation/screens/home_module/controller/home_controller.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/state/ib_state.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends IBState<HomePage, HomeController> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    controller.load();
    controller.error.addListener(_onErrorChanged);
  }

  @override
  void dispose() {
    controller.error.removeListener(_onErrorChanged);
    super.dispose();
  }

  void _onErrorChanged() {
    final error = controller.error.value;
    if (error != null && error.isNotEmpty && mounted) {
      IBSnackBar.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        controller.loading,
        controller.refreshing,
        controller.agenda,
        controller.routines,
        controller.routineSummary,
        controller.shoppingLists,
        controller.shoppingItemsByList,
      ]),
      builder: (context, _) {
        final loading = controller.loading.value;
        final showLoadingSkeleton = loading && !controller.hasContent;
        final nextActions = controller.nextActionsTimeline;
        final pastActions = controller.pastActionsToday;
        final focusTasks = controller.focusTasks;
        final openShoppingLists = controller.openShoppingLists;
        final eventsTodayCount = controller.eventsTodayCount;
        final remindersTodayCount = controller.remindersTodayCount;
        final routinesTotal = controller.routinesTotal;
        final dayCompletelyEmpty = _isDayCompletelyEmpty(
          nextActionsCount: nextActions.length,
          pastActionsCount: pastActions.length,
          focusTasksCount: focusTasks.length,
          openShoppingLists: openShoppingLists,
          eventsTodayCount: eventsTodayCount,
          remindersTodayCount: remindersTodayCount,
          routinesTotal: routinesTotal,
        );

        return ColoredBox(
          color: AppColors.background,
          child: SizedBox.expand(
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 260),
              layoutBuilder:
                  (topChild, topChildKey, bottomChild, bottomChildKey) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned.fill(
                          child: KeyedSubtree(
                            key: bottomChildKey,
                            child: bottomChild,
                          ),
                        ),
                        Positioned.fill(
                          child: KeyedSubtree(
                            key: topChildKey,
                            child: topChild,
                          ),
                        ),
                      ],
                    );
                  },
              crossFadeState: showLoadingSkeleton
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: const Center(
                child: IBLoader(label: 'Carregando resumo...'),
              ),
              secondChild: RefreshIndicator(
                onRefresh: controller.refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  children: [
                    HomeDynamicHeader(
                      executiveSummary: controller.executiveSummary,
                      onSettingsTap: () =>
                          AppNavigation.push(AppRoutes.settings),
                      onNotificationsTap: () =>
                          AppNavigation.push(AppRoutes.notificationHistory),
                    ),
                    const SizedBox(height: 12),
                    HomeQuickAddBar(
                      onTap: () => AppNavigation.push(AppRoutes.rootCreate),
                    ),
                    const SizedBox(height: 12),
                    HomeWeekStripSection(
                      controller: controller,
                      selectedDate: _selectedDate,
                      onDayTap: (day) {
                        setState(() => _selectedDate = day);
                      },
                    ),
                    if (dayCompletelyEmpty) ...[
                      const SizedBox(height: 14),
                      HomeEmptyState(
                        onCreateTap: () =>
                            AppNavigation.push(AppRoutes.rootCreate),
                      ),
                    ] else ...[
                      const SizedBox(height: 20),
                      HomeNextActionsCarousel(
                        pastItems: pastActions,
                        nextItems: nextActions,
                        onComplete: (item) {
                          controller.markTimelineItemDone(item.id, item.type);
                        },
                      ),
                      const SizedBox(height: 16),
                      HomeBentoRow(
                        progressPercent: controller.dayProgressPercent,
                        routinesDone: controller.routinesDone,
                        routinesTotal: controller.routinesTotal,
                        tasksDone: controller.tasksDone,
                        tasksTotal: controller.tasksTotal,
                        shoppingListCount: controller.openShoppingLists,
                        shoppingItemCount: controller.totalPendingShoppingItems,
                        eventsTodayCount: controller.eventsTodayCount,
                        remindersTodayCount: controller.remindersTodayCount,
                        todayTimeline: controller.insightsTimelineToday,
                        onShoppingTap: () =>
                            AppNavigation.push(AppRoutes.rootShopping),
                        onInsightsTap: () =>
                            AppNavigation.push(AppRoutes.rootEvents),
                      ),
                      const SizedBox(height: 12),
                      HomeFocusList(
                        tasks: focusTasks,
                        onToggleTask: controller.toggleCriticalTaskAt,
                        onSeeAllTap: () =>
                            AppNavigation.push(AppRoutes.rootReminders),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isDayCompletelyEmpty({
    required int nextActionsCount,
    required int pastActionsCount,
    required int focusTasksCount,
    required int openShoppingLists,
    required int eventsTodayCount,
    required int remindersTodayCount,
    required int routinesTotal,
  }) {
    return nextActionsCount == 0 &&
        pastActionsCount == 0 &&
        focusTasksCount == 0 &&
        openShoppingLists == 0 &&
        eventsTodayCount == 0 &&
        remindersTodayCount == 0 &&
        routinesTotal == 0;
  }
}
