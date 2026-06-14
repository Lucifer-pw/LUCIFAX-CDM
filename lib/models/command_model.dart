import 'package:lucifax_cdm/core/constants/command_types.dart';

class CommandModel {
  final String id;
  final String deviceId;
  final String senderId;
  final String senderDeviceName;
  final CommandType type;
  final Map<String, dynamic>? payload;
  final String status; // 'pending', 'executing', 'completed', 'failed'
  final Map<String, dynamic>? result;
  final DateTime createdAt;
  final DateTime? completedAt;

  CommandModel({
    required this.id,
    required this.deviceId,
    required this.senderId,
    required this.senderDeviceName,
    required this.type,
    this.payload,
    required this.status,
    this.result,
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'senderId': senderId,
      'senderDeviceName': senderDeviceName,
      'type': type.name,
      'payload': payload,
      'status': status,
      'result': result,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory CommandModel.fromJson(Map<String, dynamic> json) {
    return CommandModel(
      id: json['id'] ?? '',
      deviceId: json['deviceId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderDeviceName: json['senderDeviceName'] ?? '',
      type: CommandTypeExtension.fromString(json['type'] ?? 'get_info'),
      payload: json['payload'],
      status: json['status'] ?? 'pending',
      result: json['result'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
    );
  }

  CommandModel copyWith({
    String? id,
    String? deviceId,
    String? senderId,
    String? senderDeviceName,
    CommandType? type,
    Map<String, dynamic>? payload,
    String? status,
    Map<String, dynamic>? result,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return CommandModel(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      senderId: senderId ?? this.senderId,
      senderDeviceName: senderDeviceName ?? this.senderDeviceName,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      result: result ?? this.result,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
