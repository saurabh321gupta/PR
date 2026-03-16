import 'package:cloud_firestore/cloud_firestore.dart';

class BlockService {
  final _db = FirebaseFirestore.instance;

  /// Blocks a user. Adds entry to `blocks` collection.
  /// Both directions are checked so blocked users disappear from both feeds.
  Future<void> blockUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    await _db.collection('blocks').add({
      'blockedBy': currentUserId,
      'blockedUser': targetUserId,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  /// Reports a user. Adds entry to `reports` collection.
  Future<void> reportUser({
    required String reportedBy,
    required String reportedUser,
    required String reason,
  }) async {
    await _db.collection('reports').add({
      'reportedBy': reportedBy,
      'reportedUser': reportedUser,
      'reason': reason,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  /// Returns all user IDs blocked by or blocking [userId].
  Future<Set<String>> getBlockedIds(String userId) async {
    final byMe = await _db
        .collection('blocks')
        .where('blockedBy', isEqualTo: userId)
        .get();

    final ofMe = await _db
        .collection('blocks')
        .where('blockedUser', isEqualTo: userId)
        .get();

    return {
      ...byMe.docs.map((d) => d.data()['blockedUser'] as String),
      ...ofMe.docs.map((d) => d.data()['blockedBy'] as String),
    };
  }
}
