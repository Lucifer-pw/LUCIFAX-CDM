import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeBridge {
  static const MethodChannel _channel = MethodChannel('com.lucifax.cdm/native');

  static Future<bool> lockDevice() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('lockDevice');
      return result ?? false;
    } catch (e) {
      debugPrint('NativeBridge lockDevice error: $e');
      return false;
    }
  }

  static Future<bool> wipeDevice() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('wipeDevice');
      return result ?? false;
    } catch (e) {
      debugPrint('NativeBridge wipeDevice error: $e');
      return false;
    }
  }

  static Future<bool> isDeviceAdmin() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('isDeviceAdmin');
      return result ?? false;
    } catch (e) {
      debugPrint('NativeBridge isDeviceAdmin error: $e');
      return false;
    }
  }

  static Future<void> requestDeviceAdmin() async {
    try {
      await _channel.invokeMethod<void>('requestDeviceAdmin');
    } catch (e) {
      debugPrint('NativeBridge requestDeviceAdmin error: $e');
    }
  }

  static Future<String?> capturePhoto() async {
    try {
      final String? path = await _channel.invokeMethod<String>('capturePhoto');
      return path;
    } catch (e) {
      debugPrint('NativeBridge capturePhoto error: $e');
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
    } catch (e) {
      debugPrint('NativeBridge getDeviceInfo error: $e');
      return {};
    }
  }

  static Future<void> setMaxVolume() async {
    try {
      await _channel.invokeMethod<void>('setMaxVolume');
    } catch (e) {
      debugPrint('NativeBridge setMaxVolume error: $e');
    }
  }

  static Future<void> startForegroundService() async {
    try {
      await _channel.invokeMethod<void>('startForegroundService');
    } catch (e) {
      debugPrint('NativeBridge startForegroundService error: $e');
    }
  }

  static Future<void> stopForegroundService() async {
    try {
      await _channel.invokeMethod<void>('stopForegroundService');
    } catch (e) {
      debugPrint('NativeBridge stopForegroundService error: $e');
    }
  }

  static Future<Map<String, dynamic>> getSimInfo() async {
    try {
      final Map<dynamic, dynamic>? info = await _channel.invokeMethod<Map<dynamic, dynamic>>('getSimInfo');
      if (info != null) {
        return Map<String, dynamic>.from(info);
      }
      return {};
    } catch (e) {
      debugPrint('NativeBridge getSimInfo error: $e');
      return {};
    }
  }

  static Future<bool> installApk(String path) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('installApk', {'path': path});
      return result ?? false;
    } catch (e) {
      debugPrint('NativeBridge installApk error: $e');
      return false;
    }
  }

  // ======== Accessibility Service Methods ========

  static Future<bool> isAccessibilityEnabled() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled');
      return result ?? false;
    } catch (e) {
      debugPrint('NativeBridge isAccessibilityEnabled error: $e');
      return false;
    }
  }

  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod<void>('openAccessibilitySettings');
    } catch (e) {
      debugPrint('NativeBridge openAccessibilitySettings error: $e');
    }
  }

  static Future<String?> takeScreenshot() async {
    try {
      final String? path = await _channel.invokeMethod<String>('takeAccessibilityScreenshot');
      return path;
    } catch (e) {
      debugPrint('NativeBridge takeScreenshot error: $e');
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
    } catch (e) {
      debugPrint('NativeBridge dispatchClick error: $e');
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
    } catch (e) {
      debugPrint('NativeBridge dispatchSwipe error: $e');
      return false;
    }
  }
}
