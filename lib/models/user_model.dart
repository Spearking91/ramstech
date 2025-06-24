import 'dart:convert';

class UserModel {
  String username;
  String email;
  String? userId;
  List<String>? devices;

  UserModel({
    required this.username,
    required this.email,
    this.userId,
    this.devices,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      userId: json['userId'],
      devices:
          json['devices'] != null ? List<String>.from(json['devices']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'userId': userId,
      'devices': devices,
    };
  }

  void addDevice(String deviceMac) {
    devices ??= [];
    if (!devices!.contains(deviceMac)) {
      devices!.add(deviceMac);
    }
  }

  void removeDevice(String deviceMac) {
    devices?.remove(deviceMac);
  }

  bool hasDevice(String deviceMac) {
    return devices?.contains(deviceMac) ?? false;
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
