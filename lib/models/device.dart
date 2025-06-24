class DeviceModel {
  final String id;
  final String name;
  final String userId;

  DeviceModel({
    required this.id,
    required this.name,
    required this.userId,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['deviceId'] ?? '',
      name: json['name'] ?? '',
      userId: json['userId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': id,
      'name': name,
      'userId': userId,
    };
  }
}