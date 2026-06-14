class DeviceModel {
  final String id;
  final String userId;
  final String deviceName;
  final String model;
  final String manufacturer;
  final String fcmToken;
  final DateTime lastSeen;
  final double? latitude;
  final double? longitude;
  final int battery;
  final bool isOnline;
  final Map<String, dynamic> simInfo;
  final String mode; // 'device' or 'commander'
  final String platform; // 'android' or 'web'
  final bool isLocked;
  final String customMessage;
  final bool isScreenStreaming;
  final int lastScreenUpdate;

  DeviceModel({
    required this.id,
    required this.userId,
    required this.deviceName,
    required this.model,
    required this.manufacturer,
    required this.fcmToken,
    required this.lastSeen,
    this.latitude,
    this.longitude,
    required this.battery,
    required this.isOnline,
    required this.simInfo,
    required this.mode,
    required this.platform,
    this.isLocked = false,
    this.customMessage = '',
    this.isScreenStreaming = false,
    this.lastScreenUpdate = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'deviceName': deviceName,
      'model': model,
      'manufacturer': manufacturer,
      'fcmToken': fcmToken,
      'lastSeen': lastSeen.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'battery': battery,
      'isOnline': isOnline,
      'simInfo': simInfo,
      'mode': mode,
      'platform': platform,
      'isLocked': isLocked,
      'customMessage': customMessage,
      'isScreenStreaming': isScreenStreaming,
      'lastScreenUpdate': lastScreenUpdate,
    };
  }

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      deviceName: json['deviceName'] ?? '',
      model: json['model'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      fcmToken: json['fcmToken'] ?? '',
      lastSeen: json['lastSeen'] != null 
          ? DateTime.parse(json['lastSeen']) 
          : DateTime.now(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      battery: json['battery'] ?? 0,
      isOnline: json['isOnline'] ?? false,
      simInfo: json['simInfo'] != null ? Map<String, dynamic>.from(json['simInfo']) : {},
      mode: json['mode'] ?? 'device',
      platform: json['platform'] ?? 'android',
      isLocked: json['isLocked'] ?? false,
      customMessage: json['customMessage'] ?? '',
      isScreenStreaming: json['isScreenStreaming'] ?? false,
      lastScreenUpdate: json['lastScreenUpdate'] ?? 0,
    );
  }

  DeviceModel copyWith({
    String? id,
    String? userId,
    String? deviceName,
    String? model,
    String? manufacturer,
    String? fcmToken,
    DateTime? lastSeen,
    double? latitude,
    double? longitude,
    int? battery,
    bool? isOnline,
    Map<String, dynamic>? simInfo,
    String? mode,
    String? platform,
    bool? isLocked,
    String? customMessage,
    bool? isScreenStreaming,
    int? lastScreenUpdate,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceName: deviceName ?? this.deviceName,
      model: model ?? this.model,
      manufacturer: manufacturer ?? this.manufacturer,
      fcmToken: fcmToken ?? this.fcmToken,
      lastSeen: lastSeen ?? this.lastSeen,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      battery: battery ?? this.battery,
      isOnline: isOnline ?? this.isOnline,
      simInfo: simInfo ?? this.simInfo,
      mode: mode ?? this.mode,
      platform: platform ?? this.platform,
      isLocked: isLocked ?? this.isLocked,
      customMessage: customMessage ?? this.customMessage,
      isScreenStreaming: isScreenStreaming ?? this.isScreenStreaming,
      lastScreenUpdate: lastScreenUpdate ?? this.lastScreenUpdate,
    );
  }
}
