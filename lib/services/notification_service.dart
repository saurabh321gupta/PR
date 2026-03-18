import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../navigation_key.dart';
import '../screens/chat/chat_screen.dart';
import '../models/user_model.dart';

/// Top-level background handler — must be a top-level function (not a class method).
/// Firebase is already initialized by the time this runs.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📬 Background message: ${message.messageId}');
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _db = FirebaseFirestore.instance;

  /// Call from HomeScreen.initState() after the user is signed in.
  /// Does NOT request permission — that's handled by NotificationScreen.
  static Future<void> init() async {
    // Only save token if permission was already granted
    final settings = await _messaging.getNotificationSettings();
    debugPrint('🔔 Notification permission: ${settings.authorizationStatus}');
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _saveToken();
    }

    // Refresh token whenever it changes (e.g. after reinstall)
    _messaging.onTokenRefresh.listen(_updateToken);

    // Foreground message — show in-app snackbar
    FirebaseMessaging.onMessage.listen(_handleForeground);

    // Background tap — app was backgrounded, user tapped notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // Terminated tap — app was closed, user tapped notification
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleTap(initial);
  }

  // ── Token management ─────────────────────────────────────────────────────

  static Future<void> _saveToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    await _db.collection('users').doc(uid).update({'fcmToken': token});
    debugPrint('📲 FCM token saved for $uid');
  }

  static Future<void> _updateToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({'fcmToken': token});
    debugPrint('📲 FCM token refreshed');
  }

  // ── Message handlers ─────────────────────────────────────────────────────

  static void _handleForeground(RemoteMessage message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            if (body.isNotEmpty)
              Text(body, style: const TextStyle(color: Colors.white70)),
          ],
        ),
        backgroundColor: Colors.pink.shade600,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () => _handleTap(message),
        ),
      ),
    );
  }

  static Future<void> _handleTap(RemoteMessage message) async {
    final data = message.data;
    final type = data['type'];
    final matchId = data['matchId'];

    if (matchId == null) return;

    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    // Fetch the other user for ChatScreen
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid == null) return;

      final matchDoc =
          await FirebaseFirestore.instance.collection('matches').doc(matchId).get();
      if (!matchDoc.exists) return;

      final users = List<String>.from(matchDoc.data()?['users'] ?? []);
      final otherUserId = users.firstWhere((id) => id != currentUid,
          orElse: () => '');
      if (otherUserId.isEmpty) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .get();
      if (!userDoc.exists) return;

      final otherUser = UserModel.fromMap(otherUserId, userDoc.data()!);

      if (type == 'match' || type == 'message') {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              matchId: matchId,
              otherUser: otherUser,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Notification tap navigation failed: $e');
    }
  }
}
