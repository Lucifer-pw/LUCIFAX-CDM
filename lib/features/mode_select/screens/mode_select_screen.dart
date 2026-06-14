import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:lucifax_cdm/core/constants/app_colors.dart';
import 'package:lucifax_cdm/core/constants/app_strings.dart';
import 'package:lucifax_cdm/core/services/auth_service.dart';
import 'package:lucifax_cdm/core/services/device_service.dart';
import 'package:lucifax_cdm/core/services/github_service.dart';

class ModeSelectScreen extends ConsumerStatefulWidget {
  const ModeSelectScreen({super.key});

  @override
  ConsumerState<ModeSelectScreen> createState() => _ModeSelectScreenState();
}

class _ModeSelectScreenState extends ConsumerState<ModeSelectScreen> {
  bool _isLoading = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersionAndCheckUpdates();
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

  void _selectMode(String mode) async {
    setState(() => _isLoading = true);
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      try {
        final deviceService = ref.read(deviceServiceProvider);
        final currentDevice = await deviceService.registerOrUpdateCurrentDevice(
          userId: user.uid,
          mode: mode,
        );

        ref.read(activeDeviceProvider.notifier).state = currentDevice;

        if (mounted) {
          if (mode == 'device') {
            context.go('/device');
          } else {
            context.go('/commander');
          }
        }
      } catch (e) {
        debugPrint('Error selecting mode: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Terjadi kesalahan: $e')),
          );
        }
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Widget _buildModeCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.glassBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.15),
              ),
              child: Icon(icon, size: 36, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).logout();
              if (mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, Color(0xFF0F172A)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppStrings.chooseModeTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 28),
                    ).animate().fadeIn(),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.chooseModeSubtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 48),
                    
                    _buildModeCard(
                      title: AppStrings.deviceModeTitle,
                      description: AppStrings.deviceModeDesc,
                      icon: Icons.shield,
                      color: AppColors.primaryAccent,
                      onTap: () => _selectMode('device'),
                    ).animate().fade(delay: 400.ms).slideX(begin: -0.1),
                    
                    const SizedBox(height: 24),
                    
                    _buildModeCard(
                      title: AppStrings.commanderModeTitle,
                      description: AppStrings.commanderModeDesc,
                      icon: Icons.admin_panel_settings,
                      color: AppColors.success,
                      onTap: () => _selectMode('commander'),
                    ).animate().fade(delay: 600.ms).slideX(begin: 0.1),
                    
                    const SizedBox(height: 32),
                    Text(
                      _appVersion,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate().fade(delay: 800.ms),
                  ],
                ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryAccent),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
