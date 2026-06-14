import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucifax_cdm/core/constants/app_colors.dart';
import 'package:lucifax_cdm/core/services/auth_service.dart';
import 'package:lucifax_cdm/features/auth/screens/login_screen.dart';
import 'package:lucifax_cdm/features/auth/screens/setup_pin_screen.dart';
import 'package:lucifax_cdm/features/auth/screens/user_home_screen.dart';
import 'package:lucifax_cdm/features/mode_select/screens/mode_select_screen.dart';
import 'package:lucifax_cdm/features/device/screens/device_status_screen.dart';
import 'package:lucifax_cdm/features/commander/screens/dashboard_screen.dart';
import 'package:lucifax_cdm/features/commander/screens/map_tracking_screen.dart';
import 'package:lucifax_cdm/features/commander/screens/captured_photos_screen.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final userModelAsync = ref.watch(userModelProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authServiceProvider).authStateChanges,
    ),
    redirect: (context, state) {
      final user = authState.value;
      
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';

      // 1. Not logged in
      if (user == null) {
        if (!isLoggingIn && !isRegistering) {
          return '/login';
        }
        return null;
      }

      // 2. Logged in, wait for userModel data to load
      if (userModelAsync.isLoading) {
        if (state.matchedLocation == '/loading') return null;
        return '/loading';
      }

      final userModel = userModelAsync.value;
      if (userModel == null) {
        // Safe fallback: data not found or error. Force logout to prevent soft lock.
        ref.read(authServiceProvider).logout();
        return '/login';
      }

      // 3. Logged in, userModel is ready
      final pin = userModel.pin;
      final hasPin = pin != null && pin.trim().isNotEmpty;

      if (!hasPin) {
        if (state.matchedLocation != '/pin-setup') {
          return '/pin-setup';
        }
        return null;
      }

      final role = userModel.role;

      if (role == 'user') {
        // Normal user is ONLY allowed on /user-home
        if (state.matchedLocation != '/user-home') {
          return '/user-home';
        }
        return null;
      } else if (role == 'admin') {
        // Admin has access to commander features, mode select, etc.
        // If admin is on login/register/user-home/pin-setup/loading, redirect to mode-select
        final isRestrictedPath = isLoggingIn ||
            isRegistering ||
            state.matchedLocation == '/user-home' ||
            state.matchedLocation == '/pin-setup' ||
            state.matchedLocation == '/loading';
        if (isRestrictedPath) {
          return '/mode-select';
        }
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primaryAccent),
          ),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(isRegister: false),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const LoginScreen(isRegister: true),
      ),
      GoRoute(
        path: '/user-home',
        builder: (context, state) => const UserHomeScreen(),
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
});
