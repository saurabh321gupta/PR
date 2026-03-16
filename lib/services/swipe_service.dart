import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'block_service.dart';

class SwipeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _blockService = BlockService();

  /// Returns profiles filtered by:
  /// 1. Not already swiped / not self
  /// 2. Gender matches current user's interest
  /// 3. Mutual: the profile is also interested in current user's gender
  Future<List<UserModel>> getProfiles(String currentUserId) async {
    // Load current user to know their gender + preference
    final currentUserDoc =
        await _db.collection('users').doc(currentUserId).get();
    if (!currentUserDoc.exists) return [];

    final currentUser =
        UserModel.fromMap(currentUserId, currentUserDoc.data()!);
    final myGender = currentUser.gender;
    final myInterest = currentUser.interestedIn;

    // Get swiped + blocked IDs to exclude
    final results = await Future.wait([
      _db.collection('swipes').where('fromUserId', isEqualTo: currentUserId).get(),
      _blockService.getBlockedIds(currentUserId),
    ]);

    final swipedQuery = results[0] as dynamic;
    final blockedIds = results[1] as Set<String>;

    final excludedIds = {
      ...swipedQuery.docs.map((d) => d.data()['toUserId'] as String),
      ...blockedIds,
      currentUserId,
    };

    final usersQuery = await _db.collection('users').get();

    return usersQuery.docs
        .where((d) => !excludedIds.contains(d.id))
        .map((d) => UserModel.fromMap(d.id, d.data()))
        .where((profile) => _isMatch(profile, myGender, myInterest))
        .toList();
  }

  /// Two-way preference check:
  /// - I am interested in this profile's gender
  /// - This profile is interested in my gender
  bool _isMatch(UserModel profile, String myGender, String myInterest) {
    // Does their gender match what I'm looking for?
    final iAmInterested = myInterest == 'Everyone' ||
        (myInterest == 'Men' && profile.gender == 'Man') ||
        (myInterest == 'Women' && profile.gender == 'Woman');

    // Are they interested in my gender?
    final theyAreInterested = profile.interestedIn == 'Everyone' ||
        (myGender == 'Man' && profile.interestedIn == 'Men') ||
        (myGender == 'Woman' && profile.interestedIn == 'Women');

    return iAmInterested && theyAreInterested;
  }

  /// Records a swipe and returns true if it created a match.
  Future<bool> swipe({
    required String fromUserId,
    required String toUserId,
    required String direction, // 'like' | 'pass'
  }) async {
    await _db.collection('swipes').add({
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'direction': direction,
      'createdAt': DateTime.now().toIso8601String(),
    });

    if (direction == 'like') {
      return _checkAndCreateMatch(fromUserId, toUserId);
    }
    return false;
  }

  Future<bool> _checkAndCreateMatch(
      String userId1, String userId2) async {
    // Check if userId2 already liked userId1
    final reverse = await _db
        .collection('swipes')
        .where('fromUserId', isEqualTo: userId2)
        .where('toUserId', isEqualTo: userId1)
        .where('direction', isEqualTo: 'like')
        .get();

    if (reverse.docs.isEmpty) return false;

    // Create match document (deterministic ID)
    final ids = [userId1, userId2]..sort();
    await _db.collection('matches').doc(ids.join('_')).set({
      'users': ids,
      'createdAt': DateTime.now().toIso8601String(),
    });

    return true;
  }
}
