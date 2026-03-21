import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'navigation_key.dart';
import 'services/notification_service.dart';
import 'screens/landing_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Must be registered before runApp — handles messages when app is terminated
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const Grred());
}

class Grred extends StatelessWidget {
  const Grred({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grred',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        fontFamily: 'Roboto',
      ),
      home: const _AuthGate(),
    );
  }
}

/// Checks Firebase Auth state AND verifies Firestore profile exists.
/// - Signed in + has profile → HomeScreen
/// - Signed in but no profile (stale iOS Keychain) → signs out → LandingScreen
/// - Not signed in → LandingScreen
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _checking = true;
  bool _hasProfile = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _checking = false);
      return;
    }

    // User exists in Firebase Auth — verify they have a Firestore profile
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        if (mounted) setState(() { _hasProfile = true; _checking = false; });
      } else {
        // Auth session exists but no profile — stale Keychain token on iOS
        await FirebaseAuth.instance.signOut();
        if (mounted) setState(() => _checking = false);
      }
    } catch (_) {
      // Network error — let them through if auth exists, profile page handles it
      if (mounted) setState(() { _hasProfile = true; _checking = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.pink),
        ),
      );
    }

    if (_hasProfile) {
      return const HomeScreen();
    }

    return const LandingScreen();
  }
}
