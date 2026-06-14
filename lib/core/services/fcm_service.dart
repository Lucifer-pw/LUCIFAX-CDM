import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

Timer? _screenStreamTimer;

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
        _screenStreamTimer?.cancel();
        await deviceService.updateScreenStreamStatus(
          deviceId: deviceId,
          isStreaming: true,
        );
        
        _screenStreamTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
          try {
            final isEnabled = await NativeBridge.isAccessibilityEnabled();
            if (!isEnabled) {
              debugPrint('Accessibility Service is not enabled.');
              return;
            }
            final path = await NativeBridge.takeScreenshot();
            if (path != null && path.isNotEmpty) {
              final file = File(path);
              if (await file.exists()) {
                final ref = FirebaseService()
                    .storage
                    .ref()
                    .child('devices/$deviceId/screen_stream.jpg');
                await ref.putFile(file);
                
                // Update timestamp in firestore
                await FirebaseService().firestore
                    .collection('devices')
                    .doc(deviceId)
                    .update({
                  'lastScreenUpdate': DateTime.now().millisecondsSinceEpoch,
                });
              }
            }
          } catch (e) {
            debugPrint('Error capturing screen in timer: $e');
          }
        });
        result = {'success': true};
        break;
      case CommandType.stopScreenStream:
        _screenStreamTimer?.cancel();
        _screenStreamTimer = null;
        await deviceService.updateScreenStreamStatus(
          deviceId: deviceId,
          isStreaming: false,
        );
        result = {'success': true};
        break;
      case CommandType.performTouch:
        final actionType = payload?['type'] ?? 'click';
        final double x = (payload?['x'] ?? 0.0).toDouble();
        final double y = (payload?['y'] ?? 0.0).toDouble();
        
        bool success = false;
        if (actionType == 'click') {
          success = await NativeBridge.dispatchClick(x, y);
        } else if (actionType == 'swipe') {
          final double endX = (payload?['endX'] ?? 0.0).toDouble();
          final double endY = (payload?['endY'] ?? 0.0).toDouble();
          final int duration = payload?['duration'] ?? 300;
          success = await NativeBridge.dispatchSwipe(x, y, endX, endY, duration: duration);
        }
        result = {'success': success};
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
