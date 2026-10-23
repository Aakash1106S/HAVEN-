import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/route_constants.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/screens/home_tab_screen.dart';
import '../../features/schedules/presentation/screens/schedules_screen.dart';
import '../../features/voice/presentation/voice_control_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import 'main_shell_screen.dart';

/// GoRouter provider ?" 100% offline ESP32 standalone routing.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteConstants.dashboardPath,
    debugLogDiagnostics: false,
    routes: [
      // Splash (optional direct transition)
      GoRoute(
        path: RouteConstants.splashPath,
        name: RouteConstants.splash,
        builder: (_, __) => const SplashScreen(),
      ),

      // Main Navigation Shell (Dashboard, Schedules, Voice, Settings)
      ShellRoute(
        builder: (context, state, child) => MainShellScreen(child: child),
        routes: [
          // 1. Dashboard
          GoRoute(
            path: RouteConstants.dashboardPath,
            name: RouteConstants.dashboard,
            builder: (_, __) => const HomeTabScreen(),
          ),

          // 2. Switch Schedules & Timers
          GoRoute(
            path: RouteConstants.schedulesPath,
            name: RouteConstants.schedules,
            builder: (_, __) => const SchedulesScreen(),
          ),

          // 3. Voice Control
          GoRoute(
            path: RouteConstants.voicePath,
            name: RouteConstants.voiceControl,
            builder: (_, __) => const VoiceControlScreen(),
          ),

          // 4. Hardware Settings & Reference
          GoRoute(
            path: RouteConstants.settingsPath,
            name: RouteConstants.settings,
            builder: (_, __) => const SettingsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(state.error?.message ?? 'Unknown error'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(RouteConstants.dashboardPath),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});
