import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucifax_cdm/core/constants/app_colors.dart';
import 'package:lucifax_cdm/core/constants/app_strings.dart';
import 'package:lucifax_cdm/core/platform/native_bridge.dart';
import 'package:lucifax_cdm/core/services/background_service.dart';
import 'package:lucifax_cdm/core/services/device_service.dart';
import 'package:lucifax_cdm/core/services/fcm_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceStatusScreen extends ConsumerStatefulWidget {
  const DeviceStatusScreen({super.key});

  @override
  ConsumerState<DeviceStatusScreen> createState() => _DeviceStatusScreenState();
}

class _DeviceStatusScreenState extends ConsumerState<DeviceStatusScreen> {
  bool _isAdmin = false;
  bool _isLocationGranted = false;
  bool _isBackgroundLocationGranted = false;
  bool _isCameraGranted = false;
  bool _isNotificationGranted = false;
  bool _isPhoneStateGranted = false;
  bool _isProtectionRunning = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _initFCM();
  }

  Future<void> _initFCM() async {
    final currentDevice = ref.read(activeDeviceProvider);
    if (currentDevice != null) {
      await FcmService().initialize(currentDevice.id);
    }
  }

  Future<void> _checkPermissions() async {
    final adminActive = await NativeBridge.isDeviceAdmin();
    final locStatus = await Permission.location.status;
    final bgLocStatus = await Permission.locationAlways.status;
    final camStatus = await Permission.camera.status;
    final notifStatus = await Permission.notification.status;
    final phoneStatus = await Permission.phone.status;

    setState(() {
      _isAdmin = adminActive;
      _isLocationGranted = locStatus.isGranted;
      _isBackgroundLocationGranted = bgLocStatus.isGranted;
      _isCameraGranted = camStatus.isGranted;
      _isNotificationGranted = notifStatus.isGranted;
      _isPhoneStateGranted = phoneStatus.isGranted;
    });

    _checkServiceStatus();
  }

  void _checkServiceStatus() async {
    // For now we mock or check local storage flag
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isProtectionRunning = prefs.getBool('protection_active') ?? false;
    });
  }

  Future<void> _requestAdmin() async {
    await NativeBridge.requestDeviceAdmin();
    // Wait slightly then recheck
    Future.delayed(const Duration(seconds: 2), () => _checkPermissions());
  }

  Future<void> _requestPermission(Permission permission, Function(bool) onResult) async {
    final status = await permission.request();
    onResult(status.isGranted);
    _checkPermissions();
  }

  Future<void> _toggleProtection() async {
    if (_isProtectionRunning) {
      await BackgroundServiceManager.stop();
      await NativeBridge.stopForegroundService();
    } else {
      await BackgroundServiceManager.start();
      await NativeBridge.startForegroundService();
    }
    // Re-check
    _checkPermissions();
  }

  Widget _buildPermissionItem({
    required String title,
    required bool isGranted,
    required VoidCallback onRequest,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  isGranted ? AppStrings.enabledLabel : 'Belum aktif',
                  style: TextStyle(
                    fontSize: 13,
                    color: isGranted ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (!isGranted)
            ElevatedButton(
              onPressed: onRequest,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(90, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Aktifkan', style: TextStyle(fontSize: 12)),
            )
          else
            const Icon(Icons.check_circle, color: AppColors.success, size: 28),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentDevice = ref.watch(activeDeviceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Proteksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mode_edit_outline),
            onPressed: () => context.go('/mode-select'),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Protection Status Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.glassBackground,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isProtectionRunning ? AppColors.success.withOpacity(0.5) : AppColors.danger.withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _isProtectionRunning ? Icons.shield : Icons.shield_outlined,
                        size: 72,
                        color: _isProtectionRunning ? AppColors.success : AppColors.danger,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isProtectionRunning ? AppStrings.protectionActive : 'Proteksi Nonaktif',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isProtectionRunning ? AppStrings.protectionDesc : 'Harap aktifkan perizinan di bawah dan jalankan proteksi.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _toggleProtection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isProtectionRunning ? AppColors.danger : AppColors.success,
                        ),
                        child: Text(_isProtectionRunning ? 'Hentikan Proteksi' : 'Mulai Proteksi'),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                const Text(
                  AppStrings.permissionsTitle,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                
                _buildPermissionItem(
                  title: AppStrings.permissionAdmin,
                  isGranted: _isAdmin,
                  onRequest: _requestAdmin,
                ),
                
                _buildPermissionItem(
                  title: 'Akses Lokasi (Foreground)',
                  isGranted: _isLocationGranted,
                  onRequest: () => _requestPermission(Permission.location, (res) => setState(() => _isLocationGranted = res)),
                ),
                
                _buildPermissionItem(
                  title: AppStrings.permissionLocation,
                  isGranted: _isBackgroundLocationGranted,
                  onRequest: () => _requestPermission(Permission.locationAlways, (res) => setState(() => _isBackgroundLocationGranted = res)),
                ),
                
                _buildPermissionItem(
                  title: AppStrings.permissionCamera,
                  isGranted: _isCameraGranted,
                  onRequest: () => _requestPermission(Permission.camera, (res) => setState(() => _isCameraGranted = res)),
                ),
                
                _buildPermissionItem(
                  title: AppStrings.permissionNotification,
                  isGranted: _isNotificationGranted,
                  onRequest: () => _requestPermission(Permission.notification, (res) => setState(() => _isNotificationGranted = res)),
                ),

                _buildPermissionItem(
                  title: AppStrings.permissionState,
                  isGranted: _isPhoneStateGranted,
                  onRequest: () => _requestPermission(Permission.phone, (res) => setState(() => _isPhoneStateGranted = res)),
                ),
                
                const SizedBox(height: 16),
                if (currentDevice != null)
                  Center(
                    child: SelectableText(
                      'ID Perangkat: ${currentDevice.id}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
