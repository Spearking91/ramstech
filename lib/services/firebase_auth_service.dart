// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:ramstech/pages/home_page.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class FirebaseAuthMethod {
//   static final FirebaseAuth _auth = FirebaseAuth.instance;
//   static const String _persistenceKey = 'userPersistence';

//   static FirebaseAuth get auth => _auth;
//   static User? get user => _auth.currentUser;

//   static Future<User?> signIn(
//       {required String email, required String password}) async {
//     try {
//       final UserCredential userCredential = await _auth
//           .signInWithEmailAndPassword(email: email, password: password);
//       return userCredential.user;
//     } on FirebaseAuthException catch (e) {
//       // It's often better to throw e directly or a custom exception that wraps e
//       throw Exception(e.message ?? 'Sign in failed. Code: ${e.code}');
//     }
//   }

//   static Future<User?> signUp(
//       {required String email, required String password}) async {
//     try {
//       final userCredential = await _auth.createUserWithEmailAndPassword(
//           email: email, password: password);

//       if (userCredential.user == null) {
//         throw Exception('Failed to create user');
//       }

//       return userCredential.user;
//     } on FirebaseAuthException catch (e) {
//       throw Exception(e.message ?? 'Sign up failed. Code: ${e.code}');
//     }
//   }

//   static Future<void> signOut() async {
//     try {
//       // Clear persistence first
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.remove(_persistenceKey);

//       // Sign out from Google if signed in
//       final googleSignIn = GoogleSignIn();
//       if (await googleSignIn.isSignedIn()) {
//         await googleSignIn
//             .disconnect(); // <-- Use disconnect instead of signOut
//         await googleSignIn.signOut();
//       }

//       // Sign out from Firebase
//       await _auth.signOut();
//     } catch (e) {
//       throw Exception('Failed to sign out: ${e.toString()}');
//     }
//   }

//   static Future<bool> isUserLoggedIn() async {
//     final prefs = await SharedPreferences.getInstance();
//     final shouldPersist = prefs.getBool(_persistenceKey) ?? false;
//     return shouldPersist && _auth.currentUser != null;
//   }

//   static Future<void> setPersistance(bool persist) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(_persistenceKey, persist);
//   }

//   static Future<User?> googleSignIn() async {
//     try {
//       final googleUser = await GoogleSignIn().signIn();
//       // final googleSignIn = GoogleSignIn();
//       // await googleSignIn.disconnect(); // Always disconnect before sign-in
//       // final googleUser = await googleSignIn.signIn();
//       if (googleUser == null) {
//         // User cancelled the sign-in
//         return null;
//       }

//       final GoogleSignInAuthentication googleAuth =
//           await googleUser.authentication;
//       final AuthCredential credential = GoogleAuthProvider.credential(
//           idToken: googleAuth.idToken, accessToken: googleAuth.accessToken);

//       final UserCredential userCredential =
//           await _auth.signInWithCredential(credential);
//       await setPersistance(
//           true); // Persist session after successful Google sign-in
//       return userCredential.user;
//     } on FirebaseAuthException catch (e) {
//       throw Exception(e.message ?? 'Google Sign-In failed. Code: ${e.code}');
//     } catch (e) {
//       throw Exception(
//           'An unexpected error occurred during Google Sign-In: ${e.toString()}');
//     }
//   }

//   // Helper method to combine Google Sign-In and navigation
//   static Future<void> googleSignInAndNavigate(BuildContext context) async {
//     final User? user = await googleSignIn();
//     if (user != null && context.mounted) {
//       Navigator.pushReplacement(
//           context, MaterialPageRoute(builder: (context) => const HomePage()));
//     }
//   }
// }

// class FirebaseAuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   // Check if email exists in Firebase Auth
//   Future<bool> verifyEmailExists(String email) async {
//     try {
//       final methods = await _auth.fetchSignInMethodsForEmail(email);
//       return methods.isNotEmpty;
//     } catch (e) {
//       return false;
//     }
//   }

//   // Reset password (requires re-authentication or admin privileges)
//   Future<String?> resetPassword(String email, String newPassword) async {
//     try {
//       // This is a placeholder. In Firebase Auth, you can't directly set a user's password
//       // unless the user is signed in or you use the Admin SDK (not available on client).
//       // Instead, you should send a password reset email:
//       await _auth.sendPasswordResetEmail(email: email);
//       return null;
//     } on FirebaseAuthException catch (e) {
//       return e.message;
//     } catch (e) {
//       return "An error occurred";
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ramstech/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseAuthMethod {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _persistenceKey = 'userPersistence';

  static FirebaseAuth get auth => _auth;
  static User? get user => _auth.currentUser;

  static Future<User?> signIn(
      {required String email, required String password}) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Sign in failed. Code: ${e.code}');
    }
  }

  static Future<User?> signUp(
      {required String email, required String password}) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      if (userCredential.user == null) {
        throw Exception('Failed to create user');
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Sign up failed. Code: ${e.code}');
    }
  }

  static Future<void> signOut() async {
    try {
      // Clear persistence first
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_persistenceKey);

      // Sign out from Google if signed in
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
<<<<<<< HEAD
        await googleSignIn.disconnect();
=======
        await googleSignIn
            .disconnect(); // <-- Use disconnect instead of signOut
>>>>>>> 228cf7fec8be3486feb1c49e2f85fc203b4e7179
        await googleSignIn.signOut();
      }

      // Sign out from Firebase
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  static Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final shouldPersist = prefs.getBool(_persistenceKey) ?? false;
    return shouldPersist && _auth.currentUser != null;
  }

  static Future<void> setPersistance(bool persist) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_persistenceKey, persist);
  }

  static Future<User?> googleSignIn() async {
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.disconnect(); // Always disconnect before sign-in
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken, accessToken: googleAuth.accessToken);

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      await setPersistance(true);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Google Sign-In failed. Code: ${e.code}');
    } catch (e) {
      throw Exception(
          'An unexpected error occurred during Google Sign-In: ${e.toString()}');
    }
  }

  static Future<void> googleSignInAndNavigate(BuildContext context) async {
    final User? user = await googleSignIn();
    if (user != null && context.mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const HomePage()));
    }
  }
}

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Send password reset email to the user
  /// Returns null if successful, error message if failed
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No account found with this email address.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'too-many-requests':
          return 'Too many requests. Please try again later.';
        default:
          return e.message ?? 'Failed to send password reset email.';
      }
    } catch (e) {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Check if email exists in Firebase Auth (optional method)
  /// Note: This method may not work reliably due to Firebase security policies
  Future<bool> verifyEmailExists(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      // If we can't verify, assume the email might exist
      // to avoid revealing whether accounts exist
      return true;
    }
  }

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  /// Listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
