import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  // ─── Sign Up ───────────────────────────────────────────────────────────────

  /// Creates a Firebase Auth account and stores the internal secret in
  /// Firestore so the user can sign back in from any device via OTP.
  Future<User?> createAccount(String email) async {
    final secret = _generateSecurePassword();

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: secret,
    );

    // Store secret — used for re-authentication on sign-in
    await _db.collection('user_secrets').doc(email).set({
      'secret': secret,
      'uid': cred.user!.uid,
      'createdAt': DateTime.now().toIso8601String(),
    });

    return cred.user;
  }

  // ─── Sign In ───────────────────────────────────────────────────────────────

  /// Signs in an existing user after OTP verification.
  /// Retrieves the stored secret from Firestore and uses it to authenticate.
  Future<User?> signIn(String email) async {
    final doc = await _db.collection('user_secrets').doc(email).get();
    if (!doc.exists) throw Exception('no_account');

    final secret = doc.data()!['secret'] as String;
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: secret,
    );
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

  String _generateSecurePassword() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    final rand = Random.secure();
    return List.generate(32, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
