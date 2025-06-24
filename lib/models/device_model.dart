class DeviceModel {
  String macAddress;
  String? name;
  String? location;
  DateTime? lastSeen;
  bool isActive;

  DeviceModel({
    required this.macAddress,
    this.name,
    this.location,
    this.lastSeen,
    this.isActive = true,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      macAddress: json['macAddress'] ?? '',
      name: json['name'],
      location: json['location'],
      lastSeen:
          json['lastSeen'] != null ? DateTime.parse(json['lastSeen']) : null,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'macAddress': macAddress,
      'name': name,
      'location': location,
      'lastSeen': lastSeen?.toIso8601String(),
      'isActive': isActive,
    };
  }
}
