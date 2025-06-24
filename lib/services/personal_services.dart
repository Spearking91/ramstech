import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final FirebaseDatabase _firebaseDatabase = FirebaseDatabase.instance;

  // creation in firebase database

  Future<void> create({
    required String firebasePath,
    required Map<String, dynamic> data,
  }) async {
    DatabaseReference ref = _firebaseDatabase.ref(firebasePath);
    await ref.set(data);
  }

  Future<DataSnapshot?> read({required String firebasePath}) async {
    final DatabaseReference ref = _firebaseDatabase.ref().child(firebasePath);
    final DataSnapshot snapshot = await ref.get();
    return snapshot.exists ? snapshot : null;
  }

  Future<void> update({
    required String firebasePath,
    required Map<String, dynamic> data,
  }) async {
    DatabaseReference ref = _firebaseDatabase.ref().child(firebasePath);
    await ref.update(data);
  }

  Future<void> delete({required String firebasePath}) async {
    DatabaseReference ref = _firebaseDatabase.ref().child(firebasePath);
    await ref.remove();
  }
}
