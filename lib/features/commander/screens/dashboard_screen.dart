import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucifax_cdm/core/constants/app_colors.dart';
import 'package:lucifax_cdm/core/constants/app_strings.dart';
import 'package:lucifax_cdm/core/constants/command_types.dart';
import 'package:lucifax_cdm/core/services/auth_service.dart';
import 'package:lucifax_cdm/core/services/command_service.dart';
import 'package:lucifax_cdm/core/services/device_service.dart';
import 'package:lucifax_cdm/core/services/firebase_service.dart';
import 'package:lucifax_cdm/models/device_model.dart';

class CommanderDashboardScreen extends ConsumerStatefulWidget {
  const CommanderDashboardScreen({super.key});

  @override
  ConsumerState<CommanderDashboardScreen> createState() => _CommanderDashboardScreenState();
}

class _CommanderDashboardScreenState extends ConsumerState<CommanderDashboardScreen> {
  DeviceModel? _selectedDevice;

  void _sendRemoteCommand(CommandType type, {Map<String, dynamic>? payload}) async {
    final device = _selectedDevice;
    if (device == null) return;
    
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    try {
      final cmdService = ref.read(commandServiceProvider);
      
      // Update local state in firestore if locking/unlocking/streaming
      if (type == CommandType.lock) {
        await ref.read(deviceServiceProvider).updateLockStatus(
          deviceId: device.id,
          isLocked: true,
          customMessage: 'Perangkat ini hilang/dicuri!',
        );
      } else if (type == CommandType.unlock) {
        await ref.read(deviceServiceProvider).updateLockStatus(
          deviceId: device.id,
          isLocked: false,
        );
      }

      await cmdService.sendCommand(
        targetDeviceId: device.id,
        senderId: user.uid,
        senderDeviceName: 'Commander Web/App',
        type: type,
        payload: payload,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Perintah "${type.label}" berhasil dikirim!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Gagal mengirim perintah: $e'),
          ),
        );
      }
    }
  }

  void _promptCustomMessage() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Kirim Pesan Layar'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Pesan untuk pencuri/penemu...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                _sendRemoteCommand(CommandType.sendMessage, payload: {'message': controller.text});
              }
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  void _promptWipeConfirmation() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(AppStrings.confirmWipeTitle, style: TextStyle(color: AppColors.danger)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(AppStrings.confirmWipeDesc),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: AppStrings.confirmWipePlaceholder),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().toUpperCase() == 'WIPE') {
                Navigator.pop(context);
                _sendRemoteCommand(CommandType.wipe);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text(AppStrings.executeBtn),
          ),
        ],
      ),
    );
  }

  void _verifyPinForDevice(DeviceModel device) {
    final pinController = TextEditingController();
    String? error;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.glassBorder),
              ),
              title: const Text('Masukkan PIN Keamanan', style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Anda harus memverifikasi PIN sebelum dapat mengontrol perangkat ini.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    style: const TextStyle(fontSize: 24, letterSpacing: 16, color: Colors.white),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: '••••',
                      hintStyle: TextStyle(color: Colors.white24),
                    ),
                    onChanged: (val) {
                      if (val.length == 4) {
                        setDialogState(() {
                          error = null;
                        });
                      }
                    },
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final pin = pinController.text;
                    final isCorrect = await ref.read(authServiceProvider).verifyPin(pin);
                    if (isCorrect) {
                      Navigator.pop(context);
                      setState(() {
                        _selectedDevice = device;
                      });
                    } else {
                      setDialogState(() {
                        error = 'PIN Salah!';
                        pinController.clear();
                      });
                    }
                  },
                  child: const Text('Verifikasi'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDeviceList(List<DeviceModel> devices) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final d = devices[index];
        final isSelected = _selectedDevice?.id == d.id;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.glassBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? AppColors.primaryAccent : AppColors.glassBorder),
          ),
          child: ListTile(
            onTap: () => _verifyPinForDevice(d),
            leading: Icon(
              d.platform == 'web' ? Icons.computer : Icons.phone_android,
              color: d.isOnline ? AppColors.success : AppColors.textSecondary,
            ),
            title: Text(d.deviceName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            subtitle: Text(
              d.isOnline ? AppStrings.statusOnline : AppStrings.statusOffline,
              style: TextStyle(color: d.isOnline ? AppColors.success : AppColors.textSecondary, fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
          ),
        );
      },
    );
  }

  Widget _buildScreenMirrorView(DeviceModel device) {
    if (!device.isScreenStreaming) {
      return Container(
        margin: const EdgeInsets.only(top: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.glassBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          children: [
            const Icon(Icons.screen_share_outlined, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text(
              'Pemantauan Layar Real-Time',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            const Text(
              'Aktifkan pemantauan untuk melihat dan mengontrol layar HP ini secara langsung.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Mulai Pantau'),
              onPressed: () => _sendRemoteCommand(CommandType.startScreenStream),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      );
    }

    final bucket = FirebaseService().storage.bucket;
    final imageUrl = "https://firebasestorage.googleapis.com/v0/b/$bucket/o/devices%2F${device.id}%2Fscreen_stream.jpg?alt=media&t=${device.lastScreenUpdate}";

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glassBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryAccent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.live_tv, color: AppColors.success, size: 20),
                  SizedBox(width: 8),
                  Text('Layar Real-Time (Sentuh untuk kontrol)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.stop, color: AppColors.danger),
                tooltip: 'Hentikan Pantau',
                onPressed: () => _sendRemoteCommand(CommandType.stopScreenStream),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = width * 16 / 9; // Portrait aspect ratio standard
              
              return GestureDetector(
                onTapDown: (details) {
                  final localPos = details.localPosition;
                  final pctX = localPos.dx / width;
                  final pctY = localPos.dy / height;
                  
                  _sendRemoteCommand(
                    CommandType.performTouch,
                    payload: {
                      'type': 'click',
                      'x': pctX,
                      'y': pctY,
                    },
                  );
                },
                child: Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: AppColors.primaryAccent),
                            SizedBox(height: 12),
                            Text('Menghubungkan stream...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel(DeviceModel device) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Device Summary Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    device.deviceName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: device.isOnline ? AppColors.success.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      device.isOnline ? 'ONLINE' : 'OFFLINE',
                      style: TextStyle(
                        color: device.isOnline ? AppColors.success : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.battery_4_bar, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text('${device.battery}% Baterai', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(width: 16),
                  const Icon(Icons.history, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Update: ${device.lastSeen.hour.toString().padLeft(2, '0')}:${device.lastSeen.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        const Text(
          'Tindakan Jarak Jauh',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        
        // Command Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildCommandCard(
              type: device.isLocked ? CommandType.unlock : CommandType.lock,
              onTap: () => _sendRemoteCommand(device.isLocked ? CommandType.unlock : CommandType.lock),
            ),
            _buildCommandCard(
              type: CommandType.locate,
              onTap: () => context.push('/commander/map/${device.id}'),
            ),
            _buildCommandCard(
              type: CommandType.alarm,
              onTap: () => _sendRemoteCommand(CommandType.alarm),
            ),
            _buildCommandCard(
              type: CommandType.stopAlarm,
              onTap: () => _sendRemoteCommand(CommandType.stopAlarm),
            ),
            _buildCommandCard(
              type: CommandType.capturePhoto,
              onTap: () => context.push('/commander/photos/${device.id}'),
            ),
            _buildCommandCard(
              type: CommandType.sendMessage,
              onTap: _promptCustomMessage,
            ),
            _buildCommandCard(
              type: CommandType.getInfo,
              onTap: () => _sendRemoteCommand(CommandType.getInfo),
            ),
            _buildCommandCard(
              type: CommandType.wipe,
              onTap: _promptWipeConfirmation,
            ),
          ],
        ),

        // Screen Mirror view
        _buildScreenMirrorView(device),
      ],
    );
  }

  Widget _buildCommandCard({
    required CommandType type,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.glassBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(type.icon, size: 28, color: type.color),
            const SizedBox(height: 8),
            Text(
              type.label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userModelAsync = ref.watch(userModelProvider);
    final userModel = userModelAsync.value;
    final isAdmin = userModel?.role == 'admin';

    final Query<Map<String, dynamic>> devicesQuery = isAdmin
        ? FirebaseFirestore.instance.collection('devices')
        : FirebaseFirestore.instance
            .collection('devices')
            .where('userId', isEqualTo: user.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.dashboardTitle),
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
          child: StreamBuilder<QuerySnapshot>(
            stream: devicesQuery.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              final devices = docs.map((doc) => DeviceModel.fromJson(doc.data() as Map<String, dynamic>)).toList();

              if (devices.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Text(AppStrings.noDevicesFound),
                  ),
                );
              }

              // Automatically select first device if none is selected
              if (_selectedDevice == null && devices.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() => _selectedDevice = devices.first);
                });
              }

              // Resolve current live device model from snapshots
              final activeDevice = _selectedDevice != null
                  ? devices.firstWhere((d) => d.id == _selectedDevice!.id, orElse: () => devices.first)
                  : devices.first;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      AppStrings.activeDevices,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    _buildDeviceList(devices),
                    const SizedBox(height: 24),
                    _buildControlPanel(activeDevice),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
