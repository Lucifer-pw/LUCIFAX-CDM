import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:lucifax_cdm/core/platform/native_bridge.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  Future<void> startAlarm() async {
    if (_isPlaying) return;
    try {
      _isPlaying = true;
      
      // Request native layer to maximize audio volume
      await NativeBridge.setMaxVolume();

      // Configure player to loop and use alarm audio attributes
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      
      // Source can be an asset or url. We use a loud warning sound.
      // We fall back to a public URL or asset if it is set up.
      // Let's use a standard online link or local asset.
      // We will attempt to play a loud sound.
      await _audioPlayer.play(UrlSource('https://actions.google.com/sounds/v1/alarms/digital_watch_alarm_long.ogg'));
      
      debugPrint('Alarm service: alarm playing started.');
    } catch (e) {
      debugPrint('Alarm service error: $e');
      _isPlaying = false;
    }
  }

  Future<void> stopAlarm() async {
    if (!_isPlaying) return;
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      debugPrint('Alarm service: alarm playing stopped.');
    } catch (e) {
      debugPrint('Alarm service stop error: $e');
    }
  }
}
