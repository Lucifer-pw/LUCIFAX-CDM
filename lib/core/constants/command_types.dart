import 'package:flutter/material.dart';

enum CommandType {
  lock,
  unlock,
  locate,
  alarm,
  stopAlarm,
  capturePhoto,
  wipe,
  sendMessage,
  getInfo,
  startScreenStream,
  stopScreenStream,
  performTouch,
}

extension CommandTypeExtension on CommandType {
  String get name {
    switch (this) {
      case CommandType.lock:
        return 'lock';
      case CommandType.unlock:
        return 'unlock';
      case CommandType.locate:
        return 'locate';
      case CommandType.alarm:
        return 'alarm';
      case CommandType.stopAlarm:
        return 'stop_alarm';
      case CommandType.capturePhoto:
        return 'capture_photo';
      case CommandType.wipe:
        return 'wipe';
      case CommandType.sendMessage:
        return 'send_message';
      case CommandType.getInfo:
        return 'get_info';
      case CommandType.startScreenStream:
        return 'start_screen_stream';
      case CommandType.stopScreenStream:
        return 'stop_screen_stream';
      case CommandType.performTouch:
        return 'perform_touch';
    }
  }

  static CommandType fromString(String val) {
    return CommandType.values.firstWhere(
      (e) => e.name == val || e.toString() == val,
      orElse: () => CommandType.getInfo,
    );
  }

  String get label {
    switch (this) {
      case CommandType.lock:
        return 'Kunci HP';
      case CommandType.unlock:
        return 'Buka Kunci';
      case CommandType.locate:
        return 'Lacak GPS';
      case CommandType.alarm:
        return 'Bunyikan Alarm';
      case CommandType.stopAlarm:
        return 'Hentikan Alarm';
      case CommandType.capturePhoto:
        return 'Ambil Foto';
      case CommandType.wipe:
        return 'Wipe (Reset)';
      case CommandType.sendMessage:
        return 'Kirim Pesan';
      case CommandType.getInfo:
        return 'Info Baterai & SIM';
      case CommandType.startScreenStream:
        return 'Pantau Layar';
      case CommandType.stopScreenStream:
        return 'Hentikan Pantau';
      case CommandType.performTouch:
        return 'Sentuh Remote';
    }
  }

  IconData get icon {
    switch (this) {
      case CommandType.lock:
        return Icons.lock;
      case CommandType.unlock:
        return Icons.lock_open;
      case CommandType.locate:
        return Icons.my_location;
      case CommandType.alarm:
        return Icons.volume_up;
      case CommandType.stopAlarm:
        return Icons.volume_off;
      case CommandType.capturePhoto:
        return Icons.camera_alt;
      case CommandType.wipe:
        return Icons.delete_forever;
      case CommandType.sendMessage:
        return Icons.message;
      case CommandType.getInfo:
        return Icons.info_outline;
      case CommandType.startScreenStream:
        return Icons.screen_share;
      case CommandType.stopScreenStream:
        return Icons.stop_screen_share;
      case CommandType.performTouch:
        return Icons.touch_app;
    }
  }

  Color get color {
    switch (this) {
      case CommandType.lock:
        return Colors.blue;
      case CommandType.unlock:
        return Colors.blueAccent;
      case CommandType.locate:
        return Colors.green;
      case CommandType.alarm:
        return Colors.orange;
      case CommandType.stopAlarm:
        return Colors.grey;
      case CommandType.capturePhoto:
        return Colors.cyan;
      case CommandType.wipe:
        return Colors.red;
      case CommandType.sendMessage:
        return Colors.purple;
      case CommandType.getInfo:
        return Colors.indigo;
      case CommandType.startScreenStream:
        return Colors.tealAccent;
      case CommandType.stopScreenStream:
        return Colors.grey;
      case CommandType.performTouch:
        return Colors.amber;
    }
  }
}

