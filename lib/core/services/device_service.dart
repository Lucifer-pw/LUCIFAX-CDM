import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucifax_cdm/core/platform/native_bridge.dart';
import 'package:lucifax_cdm/core/services/firebase_service.dart';
import 'package:lucifax_cdm/models/device_model.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService();
});

final connectedDevicesProvider = StreamProvider.family<List<DeviceModel>, String>((ref, userId) {
  return ref.watch(deviceServiceProvider).streamConnectedDevices(userId);
});

final allDevicesProvider = StreamProvider<List<DeviceModel>>((ref) {
  return ref.watch(deviceServiceProvider).streamAllDevices();
});

final activeDeviceProvider = StateProvider<DeviceModel?>((ref) => null);

class DeviceService {
  final FirebaseFirestore _firestore = FirebaseService().firestore;
  final Battery _battery = Battery();

  Future<DeviceModel> registerOrUpdateCurrentDevice({
    required String userId,
    required String mode, // 'device' or 'commander'
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('lucifax_device_id');
    
    if (deviceId == null) {
      deviceId = _firestore.collection('devices').doc().id;
      await prefs.setString('lucifax_device_id', deviceId);
    }

    String deviceName = 'Unknown Device';
    String model = 'Unknown';
    String manufacturer = 'Unknown';
    String platform = kIsWeb ? 'web' : 'android';
    Map<String, dynamic> simInfo = {};

    if (kIsWeb) {
      deviceName = 'Web Browser';
      model = 'Browser';
      manufacturer = 'Web';
    } else {
      try {
        final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceName = '${androidInfo.brand} ${androidInfo.model}';
        model = androidInfo.model;
        manufacturer = androidInfo.manufacturer;
        
        simInfo = await NativeBridge.getSimInfo();
      } catch (e) {
        debugPrint('Error getting device info: $e');
      }
    }

    int batteryLevel = 100;
    try {
      batteryLevel = await _battery.batteryLevel;
    } catch (_) {}

    final String fcmToken = prefs.getString('fcm_token') ?? '';

    final device = DeviceModel(
      id: deviceId,
      userId: userId,
      deviceName: deviceName,
      model: model,
      manufacturer: manufacturer,
      fcmToken: fcmToken,
      lastSeen: DateTime.now(),
      battery: batteryLevel,
      isOnline: true,
      simInfo: simInfo,
      mode: mode,
      platform: platform,
    );

    await _firestore.collection('devices').doc(deviceId).set(
      device.toJson(),
      SetOptions(merge: true),
    );

    // Add device to user's list of devices (use set+merge to create doc if not exists)
    await _firestore.collection('users').doc(userId).set({
      'devices': FieldValue.arrayUnion([deviceId]),
    }, SetOptions(merge: true));

    return device;
  }

  Stream<List<DeviceModel>> streamConnectedDevices(String userId) {
    return _firestore
        .collection('devices')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DeviceModel.fromJson(doc.data()))
          .toList();
    });
  }

  Stream<List<DeviceModel>> streamAllDevices() {
    return _firestore
        .collection('devices')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DeviceModel.fromJson(doc.data()))
          .toList();
    });
  }

  Stream<DeviceModel?> streamDevice(String deviceId) {
    return _firestore
        .collection('devices')
        .doc(deviceId)
        .snapshots()
        .map((doc) => doc.exists && doc.data() != null 
            ? DeviceModel.fromJson(doc.data()!) 
            : null);
  }

  Future<void> updateDeviceStatus({
    required String deviceId,
    double? latitude,
    double? longitude,
    int? battery,
    bool? isOnline,
    String? fcmToken,
    Map<String, dynamic>? simInfo,
  }) async {
    final Map<String, dynamic> updates = {
      'lastSeen': DateTime.now().toIso8601String(),
    };
    if (latitude != null) updates['latitude'] = latitude;
    if (longitude != null) updates['longitude'] = longitude;
    if (battery != null) updates['battery'] = battery;
    if (isOnline != null) updates['isOnline'] = isOnline;
    if (fcmToken != null) updates['fcmToken'] = fcmToken;
    if (simInfo != null) updates['simInfo'] = simInfo;

    await _firestore.collection('devices').doc(deviceId).update(updates);
  }

  Future<void> sendHeartbeat(String deviceId) async {
    int batteryLevel = 100;
    try {
      batteryLevel = await _battery.batteryLevel;
    } catch (_) {}

    await updateDeviceStatus(
      deviceId: deviceId,
      battery: batteryLevel,
      isOnline: true,
    );
  }

  Future<void> markOffline(String deviceId) async {
    await _firestore.collection('devices').doc(deviceId).update({
      'isOnline': false,
      'lastSeen': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateLockStatus({
    required String deviceId,
    required bool isLocked,
    String customMessage = '',
  }) async {
    await _firestore.collection('devices').doc(deviceId).update({
      'isLocked': isLocked,
      'customMessage': customMessage,
    });
  }

  Future<void> updateScreenStreamStatus({
    required String deviceId,
    required bool isStreaming,
  }) async {
    await _firestore.collection('devices').doc(deviceId).update({
      'isScreenStreaming': isStreaming,
    });
  }

  Future<void> updateLastScreenUpdate(String deviceId) async {
    await _firestore.collection('devices').doc(deviceId).update({
      'lastScreenUpdate': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> deleteDevice(String userId, String deviceId) async {
    await _firestore.collection('devices').doc(deviceId).delete();
    await _firestore.collection('users').doc(userId).update({
      'devices': FieldValue.arrayRemove([deviceId]),
    });
  }
}
