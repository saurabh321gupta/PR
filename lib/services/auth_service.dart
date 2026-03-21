import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // ─── OTP Flow ──────────────────────────────────────────────────────────────

  /// Generates a 6-digit OTP, stores it in Firestore with 5-min expiry.
  /// Returns the OTP (dev convenience — remove before production).
  Future<String> sendOtp(String email) async {
    final otp = _generateOtp();
    final expiry = DateTime.now().add(const Duration(minutes: 5));

    await _db.collection('otp_verifications').doc(email).set({
      'otp': otp,
      'expiresAt': expiry.toIso8601String(),
      'verified': false,
    });

    // TODO: Replace with actual email sending via Cloud Functions
    debugPrint("[DEV] OTP for $email: $otp"); // remove before production
    return otp;
  }

  /// Verifies the OTP entered by the user.
  Future<bool> verifyOtp(String email, String enteredOtp) async {
    final doc = await _db.collection('otp_verifications').doc(email).get();

    if (!doc.exists) return false;

    final data = doc.data()!;
    final storedOtp = data['otp'] as String;
    final expiresAt = DateTime.parse(data['expiresAt'] as String);
    final isVerified = data['verified'] as bool;

    if (isVerified) return false;
    if (DateTime.now().isAfter(expiresAt)) return false;
    if (storedOtp != enteredOtp) return false;

    await doc.reference.update({'verified': true});
    return true;
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

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _generateOtp() {
    final rand = Random.secure();
    return List.generate(6, (_) => rand.nextInt(10)).join();
  }
}
