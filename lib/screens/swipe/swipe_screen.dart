import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/swipe_service.dart';
import '../../widgets/profile_card.dart';
import '../chat/chat_screen.dart';
import 'profile_detail_screen.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen>
    with SingleTickerProviderStateMixin {
  final _swipeService = SwipeService();
  final String _currentUserId =
      FirebaseAuth.instance.currentUser?.uid ?? '';

  List<UserModel> _profiles = [];
  bool _isLoading = true;

  // Drag state for top card
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

  // Fly-off animation
  late AnimationController _flyController;
  late Animation<Offset> _flyAnimation;
  String? _flyDirection; // 'like' | 'pass'

  @override
  void initState() {
    super.initState();
    _flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _flyController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _removeTopCard();
      }
    });
    _loadProfiles();
  }

  @override
  void dispose() {
    _flyController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    final profiles = await _swipeService.getProfiles(_currentUserId);
    setState(() {
      _profiles = profiles;
      _isLoading = false;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
      _isDragging = true;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    const threshold = 100.0;
    if (_dragOffset.dx > threshold) {
      _flyOff('like');
    } else if (_dragOffset.dx < -threshold) {
      _flyOff('pass');
    } else {
      // Snap back
      setState(() {
        _dragOffset = Offset.zero;
        _isDragging = false;
      });
    }
  }

  void _flyOff(String direction) {
    _flyDirection = direction;
    final targetX = direction == 'like' ? 600.0 : -600.0;

    _flyAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(targetX, _dragOffset.dy - 100),
    ).animate(CurvedAnimation(parent: _flyController, curve: Curves.easeOut));

    _flyController.forward(from: 0);
  }

  Future<void> _removeTopCard() async {
    if (_profiles.isEmpty) return;

    final topUser = _profiles.first;
    final isLike = _flyDirection == 'like';

    // Record swipe
    final isMatch = await _swipeService.swipe(
      fromUserId: _currentUserId,
      toUserId: topUser.id,
      direction: _flyDirection ?? 'pass',
    );

    setState(() {
      _profiles.removeAt(0);
      _dragOffset = Offset.zero;
      _isDragging = false;
      _flyDirection = null;
    });

    _flyController.reset();

    if (!mounted) return;

    if (isMatch && isLike) {
      final ids = [_currentUserId, topUser.id]..sort();
      final matchId = ids.join('_');
      _showMatchDialog(topUser, matchId);
    }
  }

  void _tapLike() => _flyOff('like');
  void _tapPass() => _flyOff('pass');

  void _openProfileDetail(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileDetailScreen(
          user: user,
          onLike: _tapLike,
          onPass: _tapPass,
        ),
      ),
    );
  }

  void _showMatchDialog(UserModel user, String matchId) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF0F5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite, color: Colors.pink, size: 48),
              ),
              const SizedBox(height: 12),
              const Text(
                "It's a Match!",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'You and ${user.firstName} both liked each other.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          matchId: matchId,
                          otherUser: user,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Message Now',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Keep Swiping',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'PR',
          style: TextStyle(
            color: Colors.pink,
            fontWeight: FontWeight.bold,
            fontSize: 26,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : _profiles.isEmpty
              ? _emptyState()
              : Column(
                  children: [
                    const SizedBox(height: 16),

                    // ── Card stack ───────────────────────────────────────
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 3rd card (bottom of stack)
                          if (_profiles.length > 2)
                            Positioned(
                              top: 12,
                              child: Transform.scale(
                                scale: 0.93,
                                child: ProfileCard(user: _profiles[2]),
                              ),
                            ),

                          // 2nd card
                          if (_profiles.length > 1)
                            Positioned(
                              top: 6,
                              child: Transform.scale(
                                scale: 0.96,
                                child: ProfileCard(user: _profiles[1]),
                              ),
                            ),

                          // Top card — draggable
                          AnimatedBuilder(
                            animation: _flyController,
                            builder: (_, __) {
                              final offset = _flyController.isAnimating
                                  ? _flyAnimation.value
                                  : _dragOffset;
                              return GestureDetector(
                                onTap: _flyController.isAnimating
                                    ? null
                                    : () => _openProfileDetail(_profiles.first),
                                onPanUpdate: _flyController.isAnimating
                                    ? null
                                    : _onPanUpdate,
                                onPanEnd: _flyController.isAnimating
                                    ? null
                                    : _onPanEnd,
                                child: ProfileCard(
                                  user: _profiles.first,
                                  dragOffset: offset,
                                  isTop: true,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Action buttons ───────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // NOPE button
                          _actionButton(
                            icon: Icons.close,
                            color: Colors.red.shade400,
                            size: 56,
                            onTap: _tapPass,
                          ),
                          const SizedBox(width: 32),
                          // LIKE button
                          _actionButton(
                            icon: Icons.favorite,
                            color: Colors.pink,
                            size: 64,
                            onTap: _tapLike,
                          ),
                          const SizedBox(width: 32),
                          // Super Like button (future)
                          _actionButton(
                            icon: Icons.star,
                            color: Colors.blue.shade400,
                            size: 48,
                            onTap: () {}, // TODO: super like
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.45),
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
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome, color: Colors.amber.shade600, size: 64),
          ),
          const SizedBox(height: 16),
          const Text(
            "You've seen everyone!",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check back later for new verified profiles.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _loadProfiles,
            icon: const Icon(Icons.refresh, color: Colors.pink),
            label: const Text('Refresh',
                style: TextStyle(color: Colors.pink, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}
