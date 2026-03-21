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

/// Listens to Firebase Auth state changes AND verifies Firestore profile.
/// - Signed in + has profile → HomeScreen
/// - Signed in but no profile (stale iOS Keychain) → signs out → LandingScreen
/// - Not signed in → LandingScreen
///
/// Re-evaluates every time auth state changes (sign-in, sign-out, etc.)
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late final Stream<User?> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = FirebaseAuth.instance.authStateChanges();
  }

  Future<bool> _checkProfile(User user) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) return true;

      // Auth exists but no profile — stale Keychain token on iOS
      await FirebaseAuth.instance.signOut();
      return false;
    } catch (_) {
      // Network error — let them through, profile page handles it
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, authSnapshot) {
        // Waiting for first auth emission
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.pink),
            ),
          );
        }

        final user = authSnapshot.data;

        // Not signed in → landing
        if (user == null) {
          return const LandingScreen();
        }

        // Signed in → verify Firestore profile exists
        return FutureBuilder<bool>(
          future: _checkProfile(user),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Colors.pink),
                ),
              );
            }

            final hasProfile = profileSnapshot.data ?? false;

            if (hasProfile) {
              return const HomeScreen();
            }

            // Profile check returned false (or signOut was triggered)
            return const LandingScreen();
          },
        );
      },
    );
  }
}
