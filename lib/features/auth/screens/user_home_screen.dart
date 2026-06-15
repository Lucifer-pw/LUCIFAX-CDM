import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucifax_cdm/core/constants/app_colors.dart';
import 'package:lucifax_cdm/core/constants/command_types.dart';
import 'package:lucifax_cdm/core/services/auth_service.dart';
import 'package:lucifax_cdm/core/services/command_service.dart';
import 'package:lucifax_cdm/core/services/device_service.dart';
import 'package:lucifax_cdm/core/services/background_service.dart';
import 'package:lucifax_cdm/core/services/github_service.dart';
import 'package:lucifax_cdm/core/services/fcm_service.dart';
import 'package:lucifax_cdm/core/platform/native_bridge.dart';
import 'package:lucifax_cdm/models/command_model.dart';

class UserHomeScreen extends ConsumerStatefulWidget {
  const UserHomeScreen({super.key});

  @override
  ConsumerState<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends ConsumerState<UserHomeScreen> {
  String _appVersion = '';
  StreamSubscription? _commandSubscription;

  @override
  void initState() {
    super.initState();
    _autoRegisterDeviceAndStartProtection();
    _loadVersionAndCheckUpdates();
  }

  @override
  void dispose() {
    _commandSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadVersionAndCheckUpdates() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = 'v${packageInfo.version}';
      });
      await GithubService.checkAndShowUpdateDialog(context);
    }
  }

  Future<void> _autoRegisterDeviceAndStartProtection() async {
    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user != null) {
        final deviceService = ref.read(deviceServiceProvider);
        
        // 1. Auto register device to firestore under 'device' mode
        final currentDevice = await deviceService.registerOrUpdateCurrentDevice(
          userId: user.uid,
          mode: 'device',
        );

        ref.read(activeDeviceProvider.notifier).state = currentDevice;

        // 2. Only auto-start background/foreground services if protection
        //    was previously activated AND essential permissions are granted.
        //    This prevents SecurityException crash on Android 13/14 (Redmi)
        //    when foreground service types require permissions not yet given.
        final prefs = await SharedPreferences.getInstance();
        final protectionPreviouslyActive = prefs.getBool('protection_active') ?? false;

        if (protectionPreviouslyActive) {
          final locGranted = await Permission.location.isGranted;
          final camGranted = await Permission.camera.isGranted;
          final notifGranted = await Permission.notification.isGranted;

          if (locGranted && camGranted && notifGranted) {
            await BackgroundServiceManager.start();
            await NativeBridge.startForegroundService();
            debugPrint('Protection auto-started: all permissions granted.');
          } else {
            debugPrint('Protection NOT auto-started: missing permissions '
                '(loc=$locGranted, cam=$camGranted, notif=$notifGranted)');
          }
        } else {
          debugPrint('Protection NOT auto-started: not previously activated.');
        }

        // 3. Start listening for incoming commands from Firestore in real-time
        _startCommandListener(currentDevice.id);
        
        debugPrint('Successfully auto-registered device and started command listener.');
      }
    } catch (e) {
      debugPrint('Error auto-registering device: $e');
    }
  }

  void _startCommandListener(String deviceId) {
    final commandService = ref.read(commandServiceProvider);
    _commandSubscription?.cancel();
    _commandSubscription = commandService.streamPendingCommands(deviceId).listen(
      (List<CommandModel> pendingCommands) async {
        for (final cmd in pendingCommands) {
          debugPrint('Executing command: ${cmd.type.name} (${cmd.id})');
          await executeCommandLocally(
            cmd.id,
            cmd.type,
            cmd.deviceId,
            cmd.payload,
          );
        }
      },
      onError: (e) {
        debugPrint('Command listener error: $e');
      },
    );
    debugPrint('Command listener started for device: $deviceId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background cybernetic gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.background,
                  Color(0xFF0F172A),
                  Color(0xFF020617),
                ],
              ),
            ),
          ),
          
          // Radial Glow Circles (Aesthetics)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.12),
                    blurRadius: 120,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryAccent.withOpacity(0.08),
                    blurRadius: 100,
                    spreadRadius: 30,
                  ),
                ],
              ),
            ),
          ),

          // Logout Button - Minimalist Glassmorphic top-right
          Positioned(
            top: 50,
            right: 20,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.glassBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                  tooltip: 'Keluar Akun',
                  onPressed: () async {
                    await ref.read(authServiceProvider).logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                ),
              ),
            ).animate().fadeIn(delay: 600.ms),
          ),

          // Main Center Content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Shield Logo
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.05),
                      border: Border.all(
                        color: AppColors.primaryAccent.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryAccent.withOpacity(0.1),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.shield_outlined,
                        size: 90,
                        color: AppColors.primaryAccent,
                      )
                          .animate(onPlay: (controller) => controller.repeat(reverse: true))
                          .scaleXY(
                            begin: 0.95,
                            end: 1.05,
                            duration: 2000.ms,
                            curve: Curves.easeInOut,
                          ),
                    ),
                  )
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.easeOutBack)
                      .shimmer(delay: 800.ms, duration: 1500.ms),

                  const SizedBox(height: 36),

                  // Brand Title
                  Text(
                    'LUCIFAX-CDM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4.0,
                      shadows: [
                        Shadow(
                          color: AppColors.primaryAccent.withOpacity(0.5),
                          blurRadius: 15,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 12),

                  // Subtitle & Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.glassBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pulsing Green dot indicator
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.success,
                          ),
                        )
                            .animate(onPlay: (controller) => controller.repeat(reverse: true))
                            .scaleXY(begin: 0.7, end: 1.3, duration: 800.ms)
                            .boxShadow(
                              begin: const BoxShadow(color: Colors.transparent),
                              end: const BoxShadow(color: AppColors.success, blurRadius: 6),
                            ),
                        const SizedBox(width: 10),
                        const Text(
                          'SISTEM PROTEKSI AKTIF',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 36),

                  // ===== Menu: Lindungi Perangkat Ini =====
                  InkWell(
                    onTap: () => context.go('/device'),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.15),
                            AppColors.primaryAccent.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primaryAccent.withOpacity(0.3),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryAccent.withOpacity(0.08),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryAccent.withOpacity(0.15),
                            ),
                            child: const Icon(
                              Icons.shield,
                              color: AppColors.primaryAccent,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Lindungi Perangkat Ini',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Aktifkan perizinan & jalankan proteksi',
                                  style: TextStyle(
                                    color: AppColors.textSecondary.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.primaryAccent,
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

                  const SizedBox(height: 24),
                  Text(
                    _appVersion,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
