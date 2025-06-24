class UploadModel {
  final double pms;
  final double humidity;
  final double temperature;
  final DateTime? timestamp;

  UploadModel({
    required this.pms,
    required this.humidity,
    required this.temperature,
    this.timestamp,
  });

  factory UploadModel.fromJson(Map<String, dynamic> json) {
    return UploadModel(
      pms: double.parse(json['PMS_25'].toString()),
      humidity: double.parse(json['Humidity'].toString()),
      temperature: double.parse(json['Temperature'].toString()),
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
          : null,
    );
  }

  @override
  String toString() {
    return 'PMS: $pms, Humidity: $humidity, Temp: $temperature';
  }
}
