import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class MatchWithUser {
  final String matchId;
  final UserModel otherUser;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final DateTime? lastReadAt; // current user's last-read timestamp

  MatchWithUser({
    required this.matchId,
    required this.otherUser,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageSenderId,
    this.lastReadAt,
  });

  /// True when the last message exists, was sent by the OTHER user,
  /// and was sent after we last read the chat (or we never read it).
  bool get isUnread {
    if (lastMessage == null || lastMessageAt == null) return false;
    if (lastMessageSenderId == null) return false;
    // If I sent the last message, it's not "unread"
    if (lastMessageSenderId == _cachedCurrentUid) return false;
    // No read timestamp → unread
    if (lastReadAt == null) return true;
    return lastMessageAt!.isAfter(lastReadAt!);
  }

  // Set once by the service so isUnread can compare sender
  static String? _cachedCurrentUid;
}

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessage.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] as String,
      text: data['text'] as String,
      createdAt: DateTime.parse(data['createdAt'] as String),
    );
  }
}

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Matches (real-time stream) ─────────────────────────────────────────────

  /// Real-time stream of all matches for [userId], with other user profiles.
  /// Updates whenever any match document changes (new message, read, etc.)
  Stream<List<MatchWithUser>> matchesStream(String userId) {
    // Cache uid for unread logic
    MatchWithUser._cachedCurrentUid = userId;

    return _db
        .collection('matches')
        .where('users', arrayContains: userId)
        .snapshots()
        .asyncMap((matchSnap) async {
      final results = <MatchWithUser>[];

      for (final matchDoc in matchSnap.docs) {
        final data = matchDoc.data();
        final users = List<String>.from(data['users']);
        final otherUserId = users.firstWhere((id) => id != userId);

        final userDoc = await _db.collection('users').doc(otherUserId).get();
        if (!userDoc.exists) continue;

        // Read-tracking: stored as lastReadAt_<userId> on the match doc
        final readKey = 'lastReadAt_$userId';
        final lastReadRaw = data[readKey] as String?;

        results.add(MatchWithUser(
          matchId: matchDoc.id,
          otherUser: UserModel.fromMap(userDoc.id, userDoc.data()!),
          lastMessage: data['lastMessage'] as String?,
          lastMessageAt: data['lastMessageAt'] != null
              ? DateTime.parse(data['lastMessageAt'] as String)
              : null,
          lastMessageSenderId: data['lastMessageSenderId'] as String?,
          lastReadAt: lastReadRaw != null ? DateTime.parse(lastReadRaw) : null,
        ));
      }

      // Sort: unread first, then by most recent message
      results.sort((a, b) {
        // Both null → equal
        if (a.lastMessageAt == null && b.lastMessageAt == null) return 0;
        if (a.lastMessageAt == null) return 1;
        if (b.lastMessageAt == null) return -1;
        return b.lastMessageAt!.compareTo(a.lastMessageAt!);
      });

      return results;
    });
  }

  /// One-shot fetch (kept for backward compat, but prefer matchesStream)
  Future<List<MatchWithUser>> getMatches(String userId) async {
    MatchWithUser._cachedCurrentUid = userId;

    final matchDocs = await _db
        .collection('matches')
        .where('users', arrayContains: userId)
        .get();

    final results = <MatchWithUser>[];

    for (final matchDoc in matchDocs.docs) {
      final data = matchDoc.data();
      final users = List<String>.from(data['users']);
      final otherUserId = users.firstWhere((id) => id != userId);

      final userDoc = await _db.collection('users').doc(otherUserId).get();
      if (!userDoc.exists) continue;

      final readKey = 'lastReadAt_$userId';
      final lastReadRaw = data[readKey] as String?;

      results.add(MatchWithUser(
        matchId: matchDoc.id,
        otherUser: UserModel.fromMap(userDoc.id, userDoc.data()!),
        lastMessage: data['lastMessage'] as String?,
        lastMessageAt: data['lastMessageAt'] != null
            ? DateTime.parse(data['lastMessageAt'] as String)
            : null,
        lastMessageSenderId: data['lastMessageSenderId'] as String?,
        lastReadAt: lastReadRaw != null ? DateTime.parse(lastReadRaw) : null,
      ));
    }

    results.sort((a, b) {
      if (a.lastMessageAt == null && b.lastMessageAt == null) return 0;
      if (a.lastMessageAt == null) return 1;
      if (b.lastMessageAt == null) return -1;
      return b.lastMessageAt!.compareTo(a.lastMessageAt!);
    });

    return results;
  }

  // ─── Mark as read ───────────────────────────────────────────────────────────

  /// Marks a chat as read for [userId] by writing the current timestamp.
  Future<void> markAsRead({
    required String matchId,
    required String userId,
  }) async {
    final readKey = 'lastReadAt_$userId';
    await _db.collection('matches').doc(matchId).update({
      readKey: DateTime.now().toIso8601String(),
    });
  }

  // ─── Messages ───────────────────────────────────────────────────────────────

  /// Real-time stream of messages for a match, ordered oldest → newest.
  Stream<List<ChatMessage>> messagesStream(String matchId) {
    return _db
        .collection('chats')
        .doc(matchId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromDoc).toList());
  }

  /// Sends a message and updates the match's last-message preview.
  Future<void> sendMessage({
    required String matchId,
    required String senderId,
    required String text,
  }) async {
    final now = DateTime.now().toIso8601String();

    await _db
        .collection('chats')
        .doc(matchId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'text': text.trim(),
      'createdAt': now,
    });

    // Update match preview + track who sent the last message
    await _db.collection('matches').doc(matchId).update({
      'lastMessage': text.trim(),
      'lastMessageAt': now,
      'lastMessageSenderId': senderId,
    });
  }
}
