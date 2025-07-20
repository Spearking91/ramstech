import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    return 'UserModel(username: $username, email: $email, userId: $userId, devices: $devices)';
  }
}

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  static CollectionReference get _usersCollection =>
      _firestore.collection('users');
  static CollectionReference get _devicesCollection =>
      _firestore.collection('devices');

  // Create or update user profile
  static Future<void> createUserProfile({
    required String username,
    required String email,
    String? userId,
  }) async {
    try {
      final String uid = userId ?? _auth.currentUser?.uid ?? '';

      if (uid.isEmpty) {
        throw Exception('User ID is required');
      }

      final userModel = UserModel(
        username: username,
        email: email,
        userId: uid,
        devices: [],
      );

      await _usersCollection.doc(uid).set(userModel.toJson());
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  // Get user profile
  static Future<UserModel?> getUserProfile(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Update user profile
  static Future<void> updateUserProfile({
    required String userId,
    String? username,
    String? email,
  }) async {
    try {
      Map<String, dynamic> updateData = {};

      if (username != null) updateData['username'] = username;
      if (email != null) updateData['email'] = email;

      if (updateData.isNotEmpty) {
        await _usersCollection.doc(userId).update(updateData);
      }
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Add device to user
  static Future<void> addDeviceToUser({
    required String userId,
    required String deviceId,
    required String deviceName,
    String? location,
  }) async {
    try {
      // First, create the device in the devices collection
      final deviceModel = DeviceModel(
        macAddress: deviceId,
        name: deviceName,
        location: location,
        lastSeen: DateTime.now(),
        isActive: true,
      );

      // Add userId to device data
      final deviceData = deviceModel.toJson();
      deviceData['userId'] = userId;

      await _devicesCollection.doc(deviceId).set(deviceData);

      // Then, add the device to the user's device list
      await _usersCollection.doc(userId).update({
        'devices': FieldValue.arrayUnion([deviceId])
      });
    } catch (e) {
      throw Exception('Failed to add device to user: $e');
    }
  }

  // Remove device from user
  static Future<void> removeDeviceFromUser({
    required String userId,
    required String deviceId,
  }) async {
    try {
      // Remove from user's device list
      await _usersCollection.doc(userId).update({
        'devices': FieldValue.arrayRemove([deviceId])
      });

      // Optionally, you might want to delete the device from devices collection
      // or mark it as inactive
      await _devicesCollection.doc(deviceId).update({
        'isActive': false,
      });
    } catch (e) {
      throw Exception('Failed to remove device from user: $e');
    }
  }

  // Get user's devices
  static Future<List<DeviceModel>> getUserDevices(String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) {
        return [];
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final deviceIds = List<String>.from(userData['devices'] ?? []);

      if (deviceIds.isEmpty) {
        return [];
      }

      final deviceDocs = await _devicesCollection
          .where('macAddress', whereIn: deviceIds)
          .get();

      return deviceDocs.docs
          .map(
              (doc) => DeviceModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user devices: $e');
    }
  }

  // Get device by ID
  static Future<DeviceModel?> getDevice(String deviceId) async {
    try {
      final doc = await _devicesCollection.doc(deviceId).get();
      if (doc.exists) {
        return DeviceModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get device: $e');
    }
  }

  // Update device information
  static Future<void> updateDevice({
    required String deviceId,
    String? name,
    String? location,
    bool? isActive,
  }) async {
    try {
      Map<String, dynamic> updateData = {};

      if (name != null) updateData['name'] = name;
      if (location != null) updateData['location'] = location;
      if (isActive != null) updateData['isActive'] = isActive;

      updateData['lastSeen'] = DateTime.now().toIso8601String();

      await _devicesCollection.doc(deviceId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update device: $e');
    }
  }

  // Delete user profile (also removes associated devices)
  static Future<void> deleteUserProfile(String userId) async {
    try {
      // Get user's devices first
      final userDevices = await getUserDevices(userId);

      // Delete all user's devices
      for (final device in userDevices) {
        await _devicesCollection.doc(device.macAddress).delete();
      }

      // Delete user profile
      await _usersCollection.doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user profile: $e');
    }
  }

  // Check if device ID exists
  static Future<bool> deviceExists(String deviceId) async {
    try {
      final doc = await _devicesCollection.doc(deviceId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Check if device is already assigned to another user
  static Future<bool> isDeviceAssigned(String deviceId) async {
    try {
      final querySnapshot = await _usersCollection
          .where('devices', arrayContains: deviceId)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get current user ID
  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Listen to user profile changes
  static Stream<UserModel?> listenToUserProfile(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Listen to user devices changes
  static Stream<List<DeviceModel>> listenToUserDevices(String userId) {
    return _usersCollection.doc(userId).snapshots().asyncMap((userDoc) async {
      if (!userDoc.exists) return [];

      final userData = userDoc.data() as Map<String, dynamic>;
      final deviceIds = List<String>.from(userData['devices'] ?? []);

      if (deviceIds.isEmpty) return [];

      final deviceDocs = await _devicesCollection
          .where('macAddress', whereIn: deviceIds)
          .get();

      return deviceDocs.docs
          .map(
              (doc) => DeviceModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }
}
