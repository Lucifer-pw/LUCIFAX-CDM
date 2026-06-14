import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucifax_cdm/features/auth/screens/login_screen.dart';
import 'package:lucifax_cdm/features/auth/screens/setup_pin_screen.dart';
import 'package:lucifax_cdm/features/mode_select/screens/mode_select_screen.dart';
import 'package:lucifax_cdm/features/device/screens/device_status_screen.dart';
import 'package:lucifax_cdm/features/commander/screens/dashboard_screen.dart';
import 'package:lucifax_cdm/features/commander/screens/map_tracking_screen.dart';
import 'package:lucifax_cdm/features/commander/screens/captured_photos_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(isRegister: false),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const LoginScreen(isRegister: true),
    ),
    GoRoute(
      path: '/pin-setup',
      builder: (context, state) => const SetupPinScreen(),
    ),
    GoRoute(
      path: '/mode-select',
      builder: (context, state) => const ModeSelectScreen(),
    ),
    GoRoute(
      path: '/device',
      builder: (context, state) => const DeviceStatusScreen(),
    ),
    GoRoute(
      path: '/commander',
      builder: (context, state) => const CommanderDashboardScreen(),
    ),
    GoRoute(
      path: '/commander/map/:deviceId',
      builder: (context, state) {
        final deviceId = state.pathParameters['deviceId'] ?? '';
        return MapTrackingScreen(deviceId: deviceId);
      },
    ),
    GoRoute(
      path: '/commander/photos/:deviceId',
      builder: (context, state) {
        final deviceId = state.pathParameters['deviceId'] ?? '';
        return CapturedPhotosScreen(deviceId: deviceId);
      },
    ),
  ],
);
