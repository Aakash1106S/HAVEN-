import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/route_constants.dart';

/// Main scaffold wrapping top-level navigation routes with a bottom [NavigationBar].
class MainShellScreen extends StatelessWidget {
  const MainShellScreen({
    super.key,
    required this.child,
  });

  final Widget child;

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(RouteConstants.dashboardPath)) {
      return 0;
    }
    if (location.startsWith(RouteConstants.schedulesPath)) {
      return 1;
    }
    if (location.startsWith(RouteConstants.voicePath)) {
      return 2;
    }
    if (location.startsWith(RouteConstants.settingsPath)) {
      return 3;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(RouteConstants.dashboardPath);
        break;
      case 1:
        context.go(RouteConstants.schedulesPath);
        break;
      case 2:
        context.go(RouteConstants.voicePath);
        break;
      case 3:
        context.go(RouteConstants.settingsPath);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Schedules',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_none_rounded),
            selectedIcon: Icon(Icons.mic_rounded),
            label: 'Voice',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
