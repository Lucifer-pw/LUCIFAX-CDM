class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? pin; // hashed pin
  final List<String> devices;
  final DateTime createdAt;
  final String role;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.pin,
    required this.devices,
    required this.createdAt,
    this.role = 'user',
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'pin': pin,
      'devices': devices,
      'createdAt': createdAt.toIso8601String(),
      'role': role,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      photoUrl: json['photoUrl'],
      pin: json['pin'],
      devices: json['devices'] != null 
          ? List<String>.from(json['devices']) 
          : [],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      role: json['role'] ?? 'user',
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? pin,
    List<String>? devices,
    DateTime? createdAt,
    String? role,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      pin: pin ?? this.pin,
      devices: devices ?? this.devices,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
    );
  }
}
