import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class MatchWithUser {
  final String matchId;
  final UserModel otherUser;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  MatchWithUser({
    required this.matchId,
    required this.otherUser,
    this.lastMessage,
    this.lastMessageAt,
  });
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

  // ─── Matches ───────────────────────────────────────────────────────────────

  /// Returns all matches for [userId] with the other user's profile attached.
  Future<List<MatchWithUser>> getMatches(String userId) async {
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

      results.add(MatchWithUser(
        matchId: matchDoc.id,
        otherUser: UserModel.fromMap(userDoc.id, userDoc.data()!),
        lastMessage: data['lastMessage'] as String?,
        lastMessageAt: data['lastMessageAt'] != null
            ? DateTime.parse(data['lastMessageAt'] as String)
            : null,
      ));
    }

    // Sort by most recent message first
    results.sort((a, b) {
      if (a.lastMessageAt == null && b.lastMessageAt == null) return 0;
      if (a.lastMessageAt == null) return 1;
      if (b.lastMessageAt == null) return -1;
      return b.lastMessageAt!.compareTo(a.lastMessageAt!);
    });

    return results;
  }

  // ─── Messages ──────────────────────────────────────────────────────────────

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

    // Update match preview
    await _db.collection('matches').doc(matchId).update({
      'lastMessage': text.trim(),
      'lastMessageAt': now,
    });
  }
}
