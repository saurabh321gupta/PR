import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Result from [AuthService.sendOtp].
class SendOtpResult {
  final bool devMode;
  final String? devOtp; // only set when devMode == true

  const SendOtpResult({required this.devMode, this.devOtp});
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  User? get currentUser => _auth.currentUser;

  // ─── Email existence check ─────────────────────────────────────────────────

  /// Returns true if this email already has a Grred account.
  Future<bool> emailExists(String email) async {
    final doc = await _db.collection('user_secrets').doc(email).get();
    return doc.exists;
  }

  // ─── OTP Flow (via Cloud Functions) ────────────────────────────────────────

  /// Calls the `sendOtp` Cloud Function which:
  ///   1. Generates a 6-digit OTP server-side
  ///   2. Stores it in Firestore with 5-min expiry
  ///   3. Sends it via email (unless dev mode is on)
  ///
  /// Returns [SendOtpResult] with devOtp only if dev mode is enabled.
  Future<SendOtpResult> sendOtp(String email) async {
    final callable = _functions.httpsCallable(
      'sendOtp',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );

    final result = await callable.call<Map<String, dynamic>>({'email': email});
    final data = result.data;

    final devMode = data['devMode'] as bool? ?? false;
    final devOtp = data['devOtp'] as String?;

    debugPrint('[AuthService] sendOtp → devMode=$devMode');
    return SendOtpResult(devMode: devMode, devOtp: devOtp);
  }

  /// Calls the `verifyOtp` Cloud Function for server-side OTP verification.
  /// Returns true if OTP is valid and not expired.
  Future<bool> verifyOtp(String email, String enteredOtp) async {
    try {
      final callable = _functions.httpsCallable(
        'verifyOtp',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 15)),
      );
      await callable.call<Map<String, dynamic>>({
        'email': email,
        'otp': enteredOtp,
      });
      return true;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[AuthService] verifyOtp error: ${e.code} ${e.message}');
      return false;
    }
  }

  // ─── Sign Up (via Cloud Function) ─────────────────────────────────────────

  /// Calls the `createAccount` Cloud Function, which:
  ///   1. Creates a Firebase Auth user (server-to-server, no carrier issues)
  ///   2. Stores the secret in user_secrets
  ///   3. Returns a custom token
  /// Then signs in locally with the custom token.
  Future<User?> createAccount(String email) async {
    final callable = _functions.httpsCallable(
      'createAccount',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );

    final result = await callable.call<Map<String, dynamic>>({'email': email});

    final token = result.data['token'] as String;

    // signInWithCustomToken is a lightweight single round-trip
    final cred = await _auth.signInWithCustomToken(token);
    return cred.user;
  }

  // ─── Sign In (via Cloud Function) ─────────────────────────────────────────

  /// Calls the `signInUser` Cloud Function, which:
  ///   1. Looks up user_secrets (server-side Firestore)
  ///   2. Verifies the Auth user exists
  ///   3. Returns a custom token
  /// Then signs in locally with the custom token.
  Future<User?> signIn(String email) async {
    final callable = _functions.httpsCallable(
      'signInUser',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );

    final result = await callable.call<Map<String, dynamic>>({'email': email});

    final token = result.data['token'] as String;

    final cred = await _auth.signInWithCustomToken(token);
    return cred.user;
  }

  /// Returns true if the signed-in user has a completed profile in Firestore.
  Future<bool> hasProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

}
