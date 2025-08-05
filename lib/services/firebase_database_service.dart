// services/firebase_database_service.dart
import 'package:firebase_database/firebase_database.dart';
import '../models/upload_model.dart';
import '../models/user_model.dart';
import 'firebase_auth_service.dart';

class FirebaseDatabaseMethods {
  static final _database = FirebaseDatabase.instance;

  // Constants
  static const String firebaseUrl =
      'https://ramstech-esp32-default-rtdb.firebaseio.com';
  static String defaultDeviceMac = '';

  // Get data for specific device
  static Stream<UploadModel?> getDeviceDataAsStream(String deviceMac) {
    final databaseRef =
        _database.ref().child('firsTestSystem/$deviceMac/devices');
    return databaseRef.onValue.map((event) {
      if (event.snapshot.value == null) return null;

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      if (data.isEmpty) return null;

      final latestKey = data.keys
          .reduce((a, b) => a.toString().compareTo(b.toString()) > 0 ? a : b);
      final latestData = data[latestKey] as Map<dynamic, dynamic>;
      final reading = Map<String, dynamic>.from(latestData);

      return UploadModel.fromJson(reading);
    });
  }

  // Get data for default device
  static Stream<UploadModel?> getDataAsStream() {
    return getDeviceDataAsStream(defaultDeviceMac);
  }

  // Get historical data
  static Stream<List<UploadModel>> getHistoricalDataAsStream(String deviceMac,
      {int limit = 10}) {
    final databaseRef =
        _database.ref().child('firsTestSystem/$deviceMac/devices');
    return databaseRef.limitToLast(limit).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];

      return data.entries
          .map((e) {
            final value = e.value as Map<dynamic, dynamic>;
            return UploadModel.fromJson(Map<String, dynamic>.from(value));
          })
          .toList()
          .reversed
          .toList();
    });
  }

  // Get historical data by date range
  static Future<List<UploadModel>> getHistoricalDataByDateRange(
    String deviceMac,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final databaseRef =
        _database.ref().child('firsTestSystem/$deviceMac/devices');
    final snapshot = await databaseRef.get();

    if (!snapshot.exists) return [];

    final data = snapshot.value as Map<dynamic, dynamic>;
    final List<UploadModel> filteredData = [];

    data.forEach((key, value) {
      final reading = UploadModel.fromJson(Map<String, dynamic>.from(value));
      final readingDate = reading.dateTime;

      if (readingDate != null &&
          readingDate.isAfter(startDate) &&
          readingDate.isBefore(endDate)) {
        filteredData.add(reading);
      }
    });

    return filteredData;
  }

  // User management
  static Future<void> saveUser(UserModel user) async {
    if (user.userId == null) return;

    final userRef = _database.ref().child('users/${user.userId}');
    await userRef.set(user.toJson());
  }

  static Future<UserModel?> getUser(String userId) async {
    final userRef = _database.ref().child('users/$userId');
    final snapshot = await userRef.get();

    if (snapshot.value == null) return null;

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return UserModel.fromJson(data);
  }

  static Stream<UserModel?> getUserAsStream(String userId) {
    final userRef = _database.ref().child('users/$userId');
    return userRef.onValue.map((event) {
      if (event.snapshot.value == null) return null;
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return UserModel.fromJson(data);
    });
  }

  // Device management
  static Future<void> addDeviceToUser(String userId, String deviceMac) async {
    final userRef = _database.ref().child('users/$userId');
    final snapshot = await userRef.get();

    UserModel user;
    if (snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      user = UserModel.fromJson(data);
    } else {
      final currentUser = FirebaseAuthMethod.user;
      user = UserModel(
        username: currentUser?.displayName ?? 'User',
        email: currentUser?.email ?? '',
        userId: userId,
      );
    }

    user.addDevice(deviceMac);
    await userRef.set(user.toJson());
  }

  static Future<List<String>> getUserDevices(String userId) async {
    final user = await getUser(userId);
    return user?.devices ?? [];
  }
}
