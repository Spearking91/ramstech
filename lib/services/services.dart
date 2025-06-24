// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:ramstech/models/upload.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:ramstech/models/user_model.dart';

// import 'package:shared_preferences/shared_preferences.dart';

// class FirebaseDatabaseMethods {
//   FirebaseDatabaseMethods._();
//   static final database = FirebaseDatabase.instance;

//   //As stream
//   static Stream<UploadModel> getDataAsStream() {
//     // Check if user is authenticated
//     if (FirebaseAuth.instance.currentUser == null) {
//       throw Exception('User must be authenticated to access data');
//     }

//     final databaseRef = database
//         .ref()
//         .child("${Constants.firebasePath}/3C:8A:1F:A7:47:3C/devices");
//     return databaseRef.orderByKey().limitToLast(1).onValue.map((event) {
//       if (event.snapshot.value == null) {
//         throw Exception('No data available');
//       }
//       final data = event.snapshot.value as Map<dynamic, dynamic>;
//       final latestData = data.values.first;
//       final reading = Map<String, dynamic>.from(latestData as Map);
//       return UploadModel.fromJson(reading);
//     });
//   }

//   //As future
//   static Future<UploadModel> getDataAsFuture() async {
//     // Check if user is authenticated
//     // if (FirebaseAuth.instance.currentUser == null) {
//     //   throw Exception('User must be authenticated to access data');
//     // }

//     try {
//       final databaseRef = database
//           .ref()
//           .child("${Constants.firebasePath}3C:8A:1F:A7:47:3C/devices");
//       final data = await databaseRef.orderByKey().limitToLast(1).get();

//       if (data.value == null) {
//         throw Exception('No data available');
//       }

//       final latestReading = data.value as Map<dynamic, dynamic>;
//       if (latestReading.isEmpty) {
//         throw Exception('No readings available');
//       }

//       final latestData = latestReading.values.first;
//       final reading = Map<String, dynamic>.from(latestData as Map);
//       return UploadModel.fromJson(reading);
//     } catch (e) {
//       throw Exception('Failed to fetch data: ${e.toString()}');
//     }
//   }

//   // Add this to your Firebase database methods class
//   static Stream<List<UploadModel>> getLogsAsStream() {
//     final databaseRef = FirebaseDatabase.instance.ref('readings');
//     return databaseRef
//         .limitToLast(10) // Adjust this number to control how many logs to show
//         .onValue
//         .map((event) {
//       final data = event.snapshot.value as Map<dynamic, dynamic>;

//       return data.entries.map((e) {
//         final value = e.value as Map<dynamic, dynamic>;
//         return UploadModel.fromJson(Map<String, dynamic>.from(value));
//       }).toList();
//     });
//   }

//   static Stream<List<UploadModel>> getHistoricalData() {
//     final databaseRef = database.ref().child(Constants.firebasePath);
//     // Get data from last 24 hours
//     final yesterday = DateTime.now().subtract(Duration(hours: 24));

//     return databaseRef
//         .orderByChild('timestamp')
//         .startAt(yesterday.millisecondsSinceEpoch)
//         .onValue
//         .map((event) {
//       if (event.snapshot.value == null) return [];

//       final data = event.snapshot.value as Map<dynamic, dynamic>;
//       return data.entries.map((e) {
//         final value = e.value as Map<dynamic, dynamic>;
//         return UploadModel.fromJson(Map<String, dynamic>.from(value));
//       }).toList();
//     });
//   }
// }

// class FirebaseAuthMethod {
//   const FirebaseAuthMethod._();
//   static final FirebaseAuth _auth = FirebaseAuth.instance;
//   static const String _persistenceKey = 'userPersistence';

//   static FirebaseAuth get auth => _auth;

//   static final User? _user = _auth.currentUser;

//   static User? get user => _user;

//   static Future<User?> signIn(
//       {required String email, required String password}) async {
//     try {
//       final user = await auth.signInWithEmailAndPassword(
//           email: email, password: password);

//       return user.user;
//     } on FirebaseAuthException catch (e) {
//       throw Exception(e.message);
//     } catch (e) {
//       throw Exception(e.toString());
//     }
//   }

//   static Future<User?> signUp({
//     required String email,
//     required String password,
//     required String username,
//   }) async {
//     try {
//       final userCredential = await auth.createUserWithEmailAndPassword(
//           email: email, password: password);

//       if (userCredential.user != null) {
//         // Create the user profile
//         final userModel = UserModel(
//           username: username,
//           email: email,
//           devices: [], // Initialize with empty device list
//         );

//         // Save to Firestore
//         await FirestoreService.createNewUser(userModel);
//       }

//       return userCredential.user;
//     } on FirebaseAuthException catch (e) {
//       throw Exception(e.message);
//     } catch (e) {
//       throw Exception(e.toString());
//     }
//   }

//   static Future<bool> isUserLoggedIn() async {
//     final prefs = await SharedPreferences.getInstance();
//     final shouldPersist = prefs.getBool(_persistenceKey) ?? false;
//     return shouldPersist && _auth.currentUser != null;
//   }

//   static Future<void> setPersistence(bool persist) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(_persistenceKey, persist);
//   }

//   static Future<void> signOut() async {
//     await _auth.signOut();
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(_persistenceKey, false);
//   }
// }

// class Constants {
//   Constants._();
//   static const firebaseUrl =
//       'https://ramstech-esp32-default-rtdb.firebaseio.com/';
//   static const firebasePath = 'firsTestSystem/';
// }

// class FirestoreService {
//   FirestoreService._();
//   static final _firestore = FirebaseFirestore.instance;

//   static Future<void> createNewUser(UserModel user) async {
//     try {
//       final userId = FirebaseAuth.instance.currentUser?.uid;
//       if (userId == null) throw Exception('User not authenticated');

//       await _firestore.collection('users').doc(userId).set(user.toJson());
//     } catch (e) {
//       throw Exception('Failed to create user profile: ${e.toString()}');
//     }
//   }
// }

// // import 'package:air/models/upload.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:firebase_database/firebase_database.dart';
// // import 'package:flutter/material.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';

// // class FirebaseDatabaseMethods {
// //   FirebaseDatabaseMethods._();
// //   static final _database = FirebaseDatabase.instance;
// //   static final _firestore = FirebaseFirestore.instance;

// //   // Get device IDs for current user
// //   static Stream<List<String>> getUserDeviceIds() {
// //     final userId = FirebaseAuthMethod.user?.uid;
// //     if (userId == null) return Stream.value([]);

// //     return _firestore
// //         .collection('users')
// //         .doc(userId)
// //         .snapshots()
// //         .map((snapshot) {
// //       if (!snapshot.exists) return [];
// //       final data = snapshot.data();
// //       if (data == null || !data.containsKey('deviceIds')) return [];

// //       return List<String>.from(data['deviceIds'] as List);
// //     });
// //   }

// //   // Modified to handle multiple devices
// //   static Stream<List<UploadModel>> getDataAsStream() {
// //     return getUserDeviceIds().asyncMap((deviceIds) async {
// //       final allData = await Future.wait(
// //         deviceIds.map((deviceId) {
// //           final databaseRef = _database
// //               .ref()
// //               .child("${Constants.firebasePath}/$deviceId/devices.json");
// //           return databaseRef.orderByKey().limitToLast(1).once().then((event) {
// //             if (event.snapshot.value == null) return null;
// //             final data = event.snapshot.value as Map<dynamic, dynamic>;
// //             final latestData = data.values.first;
// //             final reading = Map<String, dynamic>.from(latestData as Map);
// //             return UploadModel.fromJson(reading);
// //           });
// //         }),
// //       );

// //       return allData.whereType<UploadModel>().toList();
// //     });
// //   }

// //   // Modified future version
// //   static Future<List<UploadModel>> getDataAsFuture() async {
// //     final deviceIds = await getUserDeviceIds().first;
// //     final allData = await Future.wait(
// //       deviceIds.map((deviceId) async {
// //         final databaseRef =
// //             _database.ref().child("${Constants.firebasePath}/$deviceId");
// //         final data = await databaseRef.orderByKey().limitToLast(1).get();
// //         if (data.value == null) return null;

// //         final latestReading = data.value as Map<dynamic, dynamic>;
// //         final latestData = latestReading.values.first;
// //         final reading = Map<String, dynamic>.from(latestData as Map);
// //         return UploadModel.fromJson(reading);
// //       }),
// //     );

// //     return allData.whereType<UploadModel>().toList();
// //   }

// //   // Add this to your Firebase database methods class
// //   static Stream<List<UploadModel>> getLogsAsStream() {
// //     final databaseRef = FirebaseDatabase.instance.ref('readings');
// //     return databaseRef
// //         .limitToLast(10) // Adjust this number to control how many logs to show
// //         .onValue
// //         .map((event) {
// //       final data = event.snapshot.value as Map<dynamic, dynamic>?;
// //       if (data == null) return [];

// //       return data.entries.map((e) {
// //         final value = e.value as Map<dynamic, dynamic>;
// //         return UploadModel.fromJson(Map<String, dynamic>.from(value));
// //       }).toList();
// //     });
// //   }
// // }

// // class FirebaseAuthMethod {
// //   const FirebaseAuthMethod._();
// //   static final FirebaseAuth _auth = FirebaseAuth.instance;
// //   static FirebaseAuth get auth => _auth;

// //   static final User? _user = _auth.currentUser;

// //   static User? get user => _user;

// //   static Future<User?> signIn(
// //       {required String email, required String password}) async {
// //     try {
// //       final user = await auth.signInWithEmailAndPassword(
// //           email: email, password: password);

// //       return user.user;
// //     } on FirebaseAuthException catch (e) {
// //       throw Exception(e.message);
// //     } catch (e) {
// //       throw Exception(e.toString());
// //     }
// //   }

// //   static Future<User?> signUp(
// //       {required String email, required String password}) async {
// //     try {
// //       final user = await auth.createUserWithEmailAndPassword(
// //           email: email, password: password);

// //       return user.user;
// //     } on FirebaseAuthException catch (e) {
// //       throw Exception(e.message);
// //     } catch (e) {
// //       throw Exception(e.toString());
// //     }
// //   }
// // }

// // class Constants {
// //   Constants._();
// //   static const firebaseUrl = 'https://air-esp32-default-rtdb.firebaseio.com/';
// //   static const firebasePath = 'firsTestSystem/';


// // }


// // {
// //   "rules": {
// //     ".read": "now < 1741824000000",  // 2025-3-13
// //     ".write": "now < 1741824000000",  // 2025-3-13
// //   }
// // }


// // {
// //   "rules": {
// //     "firsTestSystem": {
// //       "3C:8A:1F:A7:47:3C": {
// //         "devices": {
// //           ".read": true,
// //           ".write": "auth != null"
// //         }
// //       }
// //     }
// //   }
// // }