import 'package:flutter/services.dart';

class NativeBridge {
  static const MethodChannel _channel = MethodChannel('com.lucifax.cdm/native');

  static Future<bool> lockDevice() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('lockDevice');
      return result ?? false;
    } on PlatformException catch (e) {
      print('NativeBridge lockDevice error: ${e.message}');
      return false;
    }
  }

  static Future<bool> wipeDevice() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('wipeDevice');
      return result ?? false;
    } on PlatformException catch (e) {
      print('NativeBridge wipeDevice error: ${e.message}');
      return false;
    }
  }

  static Future<bool> isDeviceAdmin() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('isDeviceAdmin');
      return result ?? false;
    } on PlatformException catch (e) {
      print('NativeBridge isDeviceAdmin error: ${e.message}');
      return false;
    }
  }

  static Future<void> requestDeviceAdmin() async {
    try {
      await _channel.invokeMethod<void>('requestDeviceAdmin');
    } on PlatformException catch (e) {
      print('NativeBridge requestDeviceAdmin error: ${e.message}');
    }
  }

  static Future<String?> capturePhoto() async {
    try {
      final String? path = await _channel.invokeMethod<String>('capturePhoto');
      return path;
    } on PlatformException catch (e) {
      print('NativeBridge capturePhoto error: ${e.message}');
      return null;
    }
  }

  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final Map<dynamic, dynamic>? info = await _channel.invokeMethod<Map<dynamic, dynamic>>('getDeviceInfo');
      if (info != null) {
        return Map<String, dynamic>.from(info);
      }
      return {};
    } on PlatformException catch (e) {
      print('NativeBridge getDeviceInfo error: ${e.message}');
      return {};
    }
  }

  static Future<void> setMaxVolume() async {
    try {
      await _channel.invokeMethod<void>('setMaxVolume');
    } on PlatformException catch (e) {
      print('NativeBridge setMaxVolume error: ${e.message}');
    }
  }

  static Future<void> startForegroundService() async {
    try {
      await _channel.invokeMethod<void>('startForegroundService');
    } on PlatformException catch (e) {
      print('NativeBridge startForegroundService error: ${e.message}');
    }
  }

  static Future<void> stopForegroundService() async {
    try {
      await _channel.invokeMethod<void>('stopForegroundService');
    } on PlatformException catch (e) {
      print('NativeBridge stopForegroundService error: ${e.message}');
    }
  }

  static Future<Map<String, dynamic>> getSimInfo() async {
    try {
      final Map<dynamic, dynamic>? info = await _channel.invokeMethod<Map<dynamic, dynamic>>('getSimInfo');
      if (info != null) {
        return Map<String, dynamic>.from(info);
      }
      return {};
    } on PlatformException catch (e) {
      print('NativeBridge getSimInfo error: ${e.message}');
      return {};
    }
  }

  static Future<bool> installApk(String path) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('installApk', {'path': path});
      return result ?? false;
    } on PlatformException catch (e) {
      print('NativeBridge installApk error: ${e.message}');
      return false;
    }
  }

  // ======== Accessibility Service Methods ========

  static Future<bool> isAccessibilityEnabled() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled');
      return result ?? false;
    } on PlatformException catch (e) {
      print('NativeBridge isAccessibilityEnabled error: ${e.message}');
      return false;
    }
  }

  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod<void>('openAccessibilitySettings');
    } on PlatformException catch (e) {
      print('NativeBridge openAccessibilitySettings error: ${e.message}');
    }
  }

  static Future<String?> takeScreenshot() async {
    try {
      final String? path = await _channel.invokeMethod<String>('takeAccessibilityScreenshot');
      return path;
    } on PlatformException catch (e) {
      print('NativeBridge takeScreenshot error: ${e.message}');
      return null;
    }
  }

  static Future<bool> dispatchClick(double x, double y) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('dispatchRemoteGesture', {
        'type': 'click',
        'x': x,
        'y': y,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      print('NativeBridge dispatchClick error: ${e.message}');
      return false;
    }
  }

  static Future<bool> dispatchSwipe(double startX, double startY, double endX, double endY, {int duration = 300}) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('dispatchRemoteGesture', {
        'type': 'swipe',
        'x': startX,
        'y': startY,
        'endX': endX,
        'endY': endY,
        'duration': duration,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      print('NativeBridge dispatchSwipe error: ${e.message}');
      return false;
    }
  }
}

