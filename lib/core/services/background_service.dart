import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:lucifax_cdm/core/constants/command_types.dart';
import 'package:lucifax_cdm/core/services/command_service.dart';
import 'package:lucifax_cdm/core/services/device_service.dart';
import 'package:lucifax_cdm/core/services/fcm_service.dart';
import 'package:lucifax_cdm/core/services/firebase_service.dart';
import 'package:lucifax_cdm/models/command_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundServiceManager {
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'lucifax_protection',
        initialNotificationTitle: 'Proteksi Lucifax Aktif',
        initialNotificationContent: 'Menjaga keamanan perangkat Anda latar belakang',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  static Future<void> start() async {
    final service = FlutterBackgroundService();
    await service.startService();
  }

  static Future<void> stop() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseService().initialize();
  final deviceService = DeviceService();
  final commandService = CommandService();

  final prefs = await SharedPreferences.getInstance();
  final String? deviceId = prefs.getString('lucifax_device_id');

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });

    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  // Periodic heartbeat timer every 5 minutes
  Timer.periodic(const Duration(minutes: 5), (timer) async {
    if (deviceId != null) {
      try {
        await deviceService.sendHeartbeat(deviceId);
      } catch (e) {
        debugPrint('Background heartbeat failed: $e');
      }
    }
  });

  // Initial heartbeat
  if (deviceId != null) {
    try {
      await deviceService.sendHeartbeat(deviceId);
    } catch (_) {}

    // Start listening for pending commands from Firestore in real-time
    commandService.streamPendingCommands(deviceId).listen(
      (List<CommandModel> pendingCommands) async {
        for (final cmd in pendingCommands) {
          debugPrint('BG: Executing command: ${cmd.type.name} (${cmd.id})');
          await executeCommandLocally(
            cmd.id,
            cmd.type,
            cmd.deviceId,
            cmd.payload,
          );
        }
      },
      onError: (e) {
        debugPrint('BG: Command listener error: $e');
      },
    );
    debugPrint('BG: Command listener started for device: $deviceId');
  }
}
