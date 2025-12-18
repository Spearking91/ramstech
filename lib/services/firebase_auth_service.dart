

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
        await googleSignIn.disconnect();
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
      final googleUser = await GoogleSignIn().signIn();
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
