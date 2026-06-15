import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucifax_cdm/core/constants/app_colors.dart';
import 'package:lucifax_cdm/core/constants/app_strings.dart';
import 'package:lucifax_cdm/core/constants/command_types.dart';
import 'package:lucifax_cdm/core/platform/native_bridge.dart';
import 'package:lucifax_cdm/core/services/auth_service.dart';
import 'package:lucifax_cdm/core/services/background_service.dart';
import 'package:lucifax_cdm/core/services/command_service.dart';
import 'package:lucifax_cdm/core/services/device_service.dart';
import 'package:lucifax_cdm/core/services/fcm_service.dart';
import 'package:lucifax_cdm/models/command_model.dart';
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
  bool _isAccessibilityGranted = false;
  bool _isProtectionRunning = false;
  StreamSubscription? _commandSubscription;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _initFCMAndCommandListener();
  }

  @override
  void dispose() {
    _commandSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initFCMAndCommandListener() async {
    final currentDevice = ref.read(activeDeviceProvider);
    if (currentDevice != null) {
      await FcmService().initialize(currentDevice.id);
      // Start listening for pending commands from Firestore in real-time
      final commandService = ref.read(commandServiceProvider);
      _commandSubscription = commandService.streamPendingCommands(currentDevice.id).listen(
        (List<CommandModel> pendingCommands) async {
          for (final cmd in pendingCommands) {
            debugPrint('Device: Executing command: ${cmd.type.name} (${cmd.id})');
            await executeCommandLocally(
              cmd.id,
              cmd.type,
              cmd.deviceId,
              cmd.payload,
            );
          }
        },
        onError: (e) {
          debugPrint('Device: Command listener error: $e');
        },
      );
      debugPrint('Device: Command listener started for device: ${currentDevice.id}');
    }
  }

  Future<void> _checkPermissions() async {
    final adminActive = await NativeBridge.isDeviceAdmin();
    final locStatus = await Permission.location.status;
    final bgLocStatus = await Permission.locationAlways.status;
    final camStatus = await Permission.camera.status;
    final notifStatus = await Permission.notification.status;
    final phoneStatus = await Permission.phone.status;
    final accessEnabled = await NativeBridge.isAccessibilityEnabled();

    setState(() {
      _isAdmin = adminActive;
      _isLocationGranted = locStatus.isGranted;
      _isBackgroundLocationGranted = bgLocStatus.isGranted;
      _isCameraGranted = camStatus.isGranted;
      _isNotificationGranted = notifStatus.isGranted;
      _isPhoneStateGranted = phoneStatus.isGranted;
      _isAccessibilityGranted = accessEnabled;
    });

    _checkServiceStatus();
  }

  void _checkServiceStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isProtectionRunning = prefs.getBool('protection_active') ?? false;
    });
  }

  Future<void> _requestAdmin() async {
    await NativeBridge.requestDeviceAdmin();
    Future.delayed(const Duration(seconds: 2), () => _checkPermissions());
  }

  Future<void> _requestPermission(Permission permission, Function(bool) onResult) async {
    final status = await permission.request();
    onResult(status.isGranted);
    _checkPermissions();
  }

  Future<void> _toggleProtection() async {
    final prefs = await SharedPreferences.getInstance();
    if (_isProtectionRunning) {
      await BackgroundServiceManager.stop();
      await NativeBridge.stopForegroundService();
      await prefs.setBool('protection_active', false);
      setState(() {
        _isProtectionRunning = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sistem proteksi berhasil dinonaktifkan.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } else {
      // Check if essential permissions are granted
      if (!_isAdmin) {
        _showPermissionWarning('Administrator Perangkat');
        return;
      }
      if (!_isLocationGranted) {
        _showPermissionWarning('Akses Lokasi (Foreground)');
        return;
      }
      if (!_isBackgroundLocationGranted) {
        _showPermissionWarning('Akses Lokasi Latar Belakang (Selalu Izinkan)');
        return;
      }
      if (!_isCameraGranted) {
        _showPermissionWarning('Akses Kamera');
        return;
      }
      if (!_isNotificationGranted) {
        _showPermissionWarning('Akses Notifikasi');
        return;
      }
      if (!_isPhoneStateGranted) {
        _showPermissionWarning('Akses Telepon / SIM');
        return;
      }
      if (!_isAccessibilityGranted) {
        _showPermissionWarning('Aksesibilitas (Remote Control)');
        return;
      }

      await BackgroundServiceManager.start();
      await NativeBridge.startForegroundService();
      await prefs.setBool('protection_active', true);
      setState(() {
        _isProtectionRunning = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sistem proteksi berhasil diaktifkan dan berjalan di latar belakang.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
    _checkPermissions();
  }

  void _showPermissionWarning(String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            SizedBox(width: 8),
            Text('Perizinan Diperlukan', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Harap aktifkan perizinan "$permissionName" terlebih dahulu sebelum memulai sistem proteksi.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppColors.primaryAccent)),
          ),
        ],
      ),
    );
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

  Widget _buildLockOverlay(BuildContext context, String deviceId, String customMessage) {
    return WillPopScope(
      onWillPop: () async => false, // disable hardware back button
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: LockPinVerifyView(
            deviceId: deviceId,
            customMessage: customMessage,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentDevice = ref.watch(activeDeviceProvider);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('devices').doc(currentDevice?.id).snapshots(),
      builder: (context, snapshot) {
        bool isLocked = false;
        String customMessage = "";
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          isLocked = data?['isLocked'] ?? false;
          customMessage = data?['customMessage'] ?? "";
        }

        return Stack(
          children: [
            Scaffold(
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

                        _buildPermissionItem(
                          title: 'Aksesibilitas (Remote Control)',
                          isGranted: _isAccessibilityGranted,
                          onRequest: () async {
                            await NativeBridge.openAccessibilitySettings();
                            Future.delayed(const Duration(seconds: 2), () => _checkPermissions());
                          },
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
            ),
            if (isLocked)
              _buildLockOverlay(context, currentDevice?.id ?? '', customMessage),
          ],
        );
      }
    );
  }
}

class LockPinVerifyView extends ConsumerStatefulWidget {
  final String deviceId;
  final String customMessage;
  const LockPinVerifyView({
    super.key,
    required this.deviceId,
    required this.customMessage,
  });

  @override
  ConsumerState<LockPinVerifyView> createState() => _LockPinVerifyViewState();
}

class _LockPinVerifyViewState extends ConsumerState<LockPinVerifyView> {
  final List<String> _enteredPin = [];
  String? _error;

  void _onNumberTap(String number) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin.add(number);
        _error = null;
      });

      if (_enteredPin.length == 4) {
        Future.delayed(const Duration(milliseconds: 200), () => _verifyPin());
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin.removeLast();
        _error = null;
      });
    }
  }

  void _verifyPin() async {
    final pin = _enteredPin.join();
    final isCorrect = await ref.read(authServiceProvider).verifyPin(pin);
    if (isCorrect) {
      // Unlock device
      await ref.read(deviceServiceProvider).updateLockStatus(
            deviceId: widget.deviceId,
            isLocked: false,
          );
    } else {
      setState(() {
        _enteredPin.clear();
        _error = 'PIN Salah!';
      });
    }
  }

  Widget _buildDot(int index) {
    bool active = index < _enteredPin.length;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.primaryAccent : Colors.transparent,
        border: Border.all(color: active ? AppColors.primaryAccent : Colors.white54, width: 2),
      ),
    );
  }

  Widget _buildNumKey(String text) {
    return InkWell(
      onTap: () => _onNumberTap(text),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 76,
        height: 76,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
          color: Colors.white.withOpacity(0.05),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.lock_rounded, size: 72, color: AppColors.danger),
        const SizedBox(height: 24),
        Text(
          widget.customMessage.isNotEmpty ? widget.customMessage : 'Perangkat Terkunci',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Masukkan PIN Keamanan untuk membuka',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) => _buildDot(index)),
        ),
        const SizedBox(height: 20),
        if (_error != null)
          Text(
            _error!,
            style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
          ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['1', '2', '3'].map((n) => _buildNumKey(n)).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['4', '5', '6'].map((n) => _buildNumKey(n)).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['7', '8', '9'].map((n) => _buildNumKey(n)).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 76),
                  _buildNumKey('0'),
                  InkWell(
                    onTap: _onBackspace,
                    borderRadius: BorderRadius.circular(40),
                    child: Container(
                      width: 76,
                      height: 76,
                      alignment: Alignment.center,
                      child: const Icon(Icons.backspace_outlined, size: 28, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
