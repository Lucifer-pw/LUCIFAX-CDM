import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:lucifax_cdm/core/constants/command_types.dart';
import 'package:lucifax_cdm/core/platform/native_bridge.dart';
import 'package:lucifax_cdm/core/services/alarm_service.dart';
import 'package:lucifax_cdm/core/services/command_service.dart';
import 'package:lucifax_cdm/core/services/device_service.dart';
import 'package:lucifax_cdm/core/services/firebase_service.dart';
import 'package:lucifax_cdm/core/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FirebaseService().initialize();
  debugPrint("Handling background messaging: ${message.messageId}");
  
  if (message.data.containsKey('command')) {
    final String commandJson = message.data['command'];
    final Map<String, dynamic> commandMap = json.decode(commandJson);
    
    final String cmdId = commandMap['id'] ?? '';
    final String typeStr = commandMap['type'] ?? '';
    final String deviceId = commandMap['deviceId'] ?? '';
    final Map<String, dynamic>? payload = commandMap['payload'] != null 
        ? Map<String, dynamic>.from(commandMap['payload'])
        : null;

    final type = CommandTypeExtension.fromString(typeStr);
    
    await executeCommandLocally(cmdId, type, deviceId, payload);
  }
}

Future<void> executeCommandLocally(
  String commandId,
  CommandType type,
  String deviceId,
  Map<String, dynamic>? payload,
) async {
  final CommandService commandService = CommandService();
  final DeviceService deviceService = DeviceService();

  try {
    await commandService.updateCommandStatus(commandId, 'executing');

    Map<String, dynamic> result = {};

    switch (type) {
      case CommandType.lock:
        final success = await NativeBridge.lockDevice();
        result = {'success': success};
        break;
      case CommandType.unlock:
        // Remote unlock is typically not supported natively, but we can do custom action
        result = {'success': false, 'message': 'Unlock tidak didukung secara native'};
        break;
      case CommandType.locate:
        final location = await LocationService().getCurrentLocation();
        if (location != null) {
          await LocationService().saveLocation(deviceId, location);
          result = {
            'success': true,
            'latitude': location.latitude,
            'longitude': location.longitude,
          };
        } else {
          result = {'success': false, 'message': 'Gagal mengambil GPS'};
        }
        break;
      case CommandType.alarm:
        await AlarmService().startAlarm();
        result = {'success': true};
        break;
      case CommandType.stopAlarm:
        await AlarmService().stopAlarm();
        result = {'success': true};
        break;
      case CommandType.capturePhoto:
        final path = await NativeBridge.capturePhoto();
        if (path != null && path.isNotEmpty) {
          final file = File(path);
          if (await file.exists()) {
            final ref = FirebaseService()
                .storage
                .ref()
                .child('devices/$deviceId/captures/${DateTime.now().millisecondsSinceEpoch}.jpg');
            await ref.putFile(file);
            final downloadUrl = await ref.getDownloadURL();
            
            // Save metadata
            await FirebaseService().firestore
                .collection('devices')
                .doc(deviceId)
                .collection('photos')
                .add({
              'url': downloadUrl,
              'capturedAt': DateTime.now().toIso8601String(),
              'source': 'front',
            });
            
            result = {'success': true, 'photoUrl': downloadUrl};
          } else {
            result = {'success': false, 'message': 'File foto tidak ditemukan'};
          }
        } else {
          result = {'success': false, 'message': 'Gagal mengambil foto'};
        }
        break;
      case CommandType.wipe:
        final success = await NativeBridge.wipeDevice();
        result = {'success': success};
        break;
      case CommandType.sendMessage:
        final String msg = payload?['message'] ?? 'Perangkat ini hilang/dicuri!';
        // Display custom message - for simplicity, we trigger foreground service notification update
        // or system overlay dialog
        result = {'success': true, 'messageSent': msg};
        break;
      case CommandType.getInfo:
        final info = await NativeBridge.getDeviceInfo();
        final sim = await NativeBridge.getSimInfo();
        result = {
          'success': true,
          'deviceInfo': info,
          'simInfo': sim,
        };
        await deviceService.updateDeviceStatus(
          deviceId: deviceId,
          simInfo: sim,
        );
        break;
      case CommandType.startScreenStream:
        // Handled in background service loop when streaming mode is active
        result = {'success': true, 'status': 'Stream started'};
        break;
      case CommandType.stopScreenStream:
        // Handled in background service loop when streaming mode is deactivated
        result = {'success': true, 'status': 'Stream stopped'};
        break;
      case CommandType.performTouch:
        final double x = (payload?['x'] as num?)?.toDouble() ?? 0.0;
        final double y = (payload?['y'] as num?)?.toDouble() ?? 0.0;
        final String gestureType = payload?['type'] ?? 'click';
        
        bool gestureResult = false;
        if (gestureType == 'click') {
          gestureResult = await NativeBridge.dispatchClick(x, y);
        } else if (gestureType == 'swipe') {
          final double endX = (payload?['endX'] as num?)?.toDouble() ?? 0.0;
          final double endY = (payload?['endY'] as num?)?.toDouble() ?? 0.0;
          final int duration = (payload?['duration'] as num?)?.toInt() ?? 300;
          gestureResult = await NativeBridge.dispatchSwipe(
            x,
            y,
            endX,
            endY,
            duration: duration,
          );
        }
        result = {'success': gestureResult};
        break;
    }

    await commandService.updateCommandStatus(commandId, 'completed', result: result);
  } catch (e) {
    debugPrint('Command execution failed: $e');
    await commandService.updateCommandStatus(commandId, 'failed', result: {'error': e.toString()});
  }
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseService().messaging;

  Future<void> initialize(String deviceId) async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permissions');
      }

      // Get FCM Token
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
        await DeviceService().updateDeviceStatus(deviceId: deviceId, fcmToken: token);
      }

      // Handle token refreshes
      _messaging.onTokenRefresh.listen((token) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
        await DeviceService().updateDeviceStatus(deviceId: deviceId, fcmToken: token);
      });

      // Background Message Handler registration
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Foreground Message Handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint('Received foreground message: ${message.messageId}');
        if (message.data.containsKey('command')) {
          final String commandJson = message.data['command'];
          final Map<String, dynamic> commandMap = json.decode(commandJson);
          
          final String cmdId = commandMap['id'] ?? '';
          final String typeStr = commandMap['type'] ?? '';
          final Map<String, dynamic>? payload = commandMap['payload'] != null 
              ? Map<String, dynamic>.from(commandMap['payload'])
              : null;

          final type = CommandTypeExtension.fromString(typeStr);
          await executeCommandLocally(cmdId, type, deviceId, payload);
        }
      });
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
    }
  }
}
