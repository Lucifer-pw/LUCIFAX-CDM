import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucifax_cdm/core/constants/app_colors.dart';
import 'package:lucifax_cdm/core/constants/app_strings.dart';
import 'package:lucifax_cdm/core/constants/command_types.dart';
import 'package:lucifax_cdm/core/services/auth_service.dart';
import 'package:lucifax_cdm/core/services/command_service.dart';
import 'package:lucifax_cdm/core/services/device_service.dart';
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
            onTap: () => setState(() => _selectedDevice = d),
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
              type: CommandType.lock,
              onTap: () => _sendRemoteCommand(CommandType.lock),
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

    final devicesAsync = ref.watch(connectedDevicesProvider(user.uid));

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                devicesAsync.when(
                  data: (devices) {
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

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          AppStrings.activeDevices,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        _buildDeviceList(devices),
                        const SizedBox(height: 24),
                        if (_selectedDevice != null) ...[
                          // Find latest snapshot of selected device
                          _buildControlPanel(
                            devices.firstWhere(
                              (d) => d.id == _selectedDevice!.id,
                              orElse: () => _selectedDevice!,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
