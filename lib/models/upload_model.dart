import 'package:intl/intl.dart';

class UploadModel {
  final double? temperature;
  final double? humidity;
  final double? pms;
  final double? aqi;
  final String? category;
  final String? timestamp;
  final String? deviceId;

  UploadModel({
    this.aqi,
    this.category,
    this.temperature,
    this.humidity,
    this.pms,
    this.timestamp,
    this.deviceId,
  });

  factory UploadModel.fromJson(Map<String, dynamic> json) {
    return UploadModel(
      temperature: _parseDouble(json['Temperature']),
      humidity: _parseDouble(json['Humidity']),
      pms: _parseDouble(json['Waveshare_PMS_25']),
      aqi: _parseDouble(json['Waveshare_AQI']),
      category: json['Waveshare_AQI_Category']?.toString(),
      timestamp: json['timestamp']?.toString(),
      deviceId: json['deviceId']?.toString(),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'PMS_25': pms,
      'Waveshare_AQI': aqi,
      'Waveshare_AQI_Category': category,
      'timestamp': timestamp,
      'deviceId': deviceId,
    };
  }

  DateTime? get dateTime {
    if (timestamp == null) return null;
    try {
      return DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp!));
    } catch (e) {
      return null;
    }
  }

  String? get formattedDateTime {
    final dt = dateTime;
    if (dt == null) return null;
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
  }
}
