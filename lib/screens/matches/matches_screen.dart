import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/chat_service.dart';
import '../chat/chat_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final _chatService = ChatService();
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  late Future<List<MatchWithUser>> _matchesFuture;

  @override
  void initState() {
    super.initState();
    _matchesFuture = _chatService.getMatches(_currentUserId);
  }

  void _refresh() {
    setState(() {
      _matchesFuture = _chatService.getMatches(_currentUserId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Matches',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.pink),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<MatchWithUser>>(
        future: _matchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.pink));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final matches = snapshot.data ?? [];

          if (matches.isEmpty) return _emptyState();

          return RefreshIndicator(
            color: Colors.pink,
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: matches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final match = matches[index];
                return _MatchTile(
                  match: match,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          matchId: match.matchId,
                          otherUser: match.otherUser,
                        ),
                      ),
                    );
                    _refresh(); // update last message on return
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFFCE4EC), // Pink 50
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_border, color: Colors.pink, size: 56),
          ),
          SizedBox(height: 16),
          Text(
            'No matches yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Keep swiping — your matches will appear here.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  final MatchWithUser match;
  final VoidCallback onTap;

  const _MatchTile({required this.match, required this.onTap});

  Color _avatarColor() {
    final colors = [
      Colors.pink.shade300,
      Colors.purple.shade300,
      Colors.indigo.shade300,
      Colors.teal.shade400,
      Colors.orange.shade400,
    ];
    final name = match.otherUser.firstName;
    final index = name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0;
    return colors[index];
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final user = match.otherUser;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: _avatarColor(),
              child: Text(
                user.firstName.isNotEmpty
                    ? user.firstName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Name + preview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${user.firstName}, ${user.age}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.verified,
                          size: 14, color: Colors.green.shade600),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    match.lastMessage ?? 'Say hi!',
                    style: TextStyle(
                      fontSize: 13,
                      color: match.lastMessage != null
                          ? Colors.black87
                          : Colors.grey,
                      fontStyle: match.lastMessage != null
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Time
            if (match.lastMessageAt != null)
              Text(
                _timeAgo(match.lastMessageAt),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),

            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}
