import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/swipe_service.dart';
import '../../theme/app_theme.dart';
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

  // ── Match dialog — Executive Blush style ──────────────────────────────────
  void _showMatchDialog(UserModel user, String matchId) {
    showDialog(
      context: context,
      barrierColor: AppColors.onSurface.withOpacity(0.4),
      builder: (_) => Dialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Heart icon in warm blush circle
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.primary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),

              // Headline
              Text(
                "It's a Match!",
                style: AppTextStyles.headlineLg.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'You and ${user.firstName} both liked each other.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),

              // Gradient primary button — Message Now
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.editorialGradient,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: AppShadows.fab,
                  ),
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
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Message Now',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Keep Swiping text button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Keep Swiping',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Avatar colour fallback based on name initial ──────────────────────────
  Color _avatarColor(UserModel user) {
    final colors = [
      AppColors.primaryContainer,
      AppColors.secondary,
      AppColors.tertiary,
      AppColors.secondaryFixedDim,
      AppColors.primary,
    ];
    final index = user.firstName.isNotEmpty
        ? user.firstName.codeUnitAt(0) % colors.length
        : 0;
    return colors[index];
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.8),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.surfaceContainerLow.withOpacity(0.5),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      // Left: menu icon
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: IconButton(
                          onPressed: () {}, // placeholder
                          icon: const Icon(Icons.menu_rounded),
                          color: AppColors.primary,
                          iconSize: 24,
                          splashRadius: 22,
                        ),
                      ),
                      // Center: brand
                      Expanded(
                        child: Center(
                          child: Text('Grred', style: AppTextStyles.brand),
                        ),
                      ),
                      // Right: tune/filter icon
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: IconButton(
                          onPressed: () {}, // placeholder
                          icon: const Icon(Icons.tune_rounded),
                          color: AppColors.primary,
                          iconSize: 24,
                          splashRadius: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            )
          : _profiles.isEmpty
              ? _emptyState()
              : Column(
                  children: [
                    // Space below the glassmorphic app bar
                    SizedBox(
                      height: MediaQuery.of(context).padding.top + 56 + 8,
                    ),

                    // ── Card stack ──────────────────────────────────────────
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final cardWidth = constraints.maxWidth - 32;
                          final cardHeight = constraints.maxHeight * 0.85;

                          return Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              // Decorative background card 2 (bottom)
                              if (_profiles.length > 2)
                                Positioned(
                                  top: 8,
                                  child: Transform.rotate(
                                    angle: 0.052, // ~3 degrees
                                    child: Container(
                                      width: cardWidth - 16,
                                      height: cardHeight,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainerLowest
                                            .withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.lg),
                                        boxShadow: AppShadows.card,
                                      ),
                                    ),
                                  ),
                                ),

                              // Decorative background card 1
                              if (_profiles.length > 1)
                                Positioned(
                                  top: 4,
                                  child: Transform.rotate(
                                    angle: -0.035, // ~-2 degrees
                                    child: Container(
                                      width: cardWidth - 8,
                                      height: cardHeight,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainerLowest
                                            .withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.lg),
                                        boxShadow: AppShadows.card,
                                      ),
                                    ),
                                  ),
                                ),

                              // Top card — draggable, full editorial design
                              AnimatedBuilder(
                                animation: _flyController,
                                builder: (_, __) {
                                  final offset = _flyController.isAnimating
                                      ? _flyAnimation.value
                                      : _dragOffset;
                                  final rotation = offset.dx * 0.0015;
                                  final user = _profiles.first;

                                  return Transform.translate(
                                    offset: offset,
                                    child: Transform.rotate(
                                      angle: rotation,
                                      child: GestureDetector(
                                        onTap: _flyController.isAnimating
                                            ? null
                                            : () => _openProfileDetail(user),
                                        onPanUpdate:
                                            _flyController.isAnimating
                                                ? null
                                                : _onPanUpdate,
                                        onPanEnd: _flyController.isAnimating
                                            ? null
                                            : _onPanEnd,
                                        child: _editorialCard(
                                          user: user,
                                          width: cardWidth,
                                          height: cardHeight,
                                          showOverlays: true,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Action buttons ───────────────────────────────────────
                    Padding(
                      padding: EdgeInsets.only(
                        bottom:
                            MediaQuery.of(context).padding.bottom + 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Dislike — 64px, white, close icon
                          _dislikeButton(onTap: _tapPass),
                          const SizedBox(width: 10),
                          // Super Like — 56px, white, stars icon, tertiary green
                          _superLikeButton(onTap: () {}), // TODO: super like
                          const SizedBox(width: 10),
                          // Like — 64px, gradient, heart icon
                          _likeButton(onTap: _tapLike),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  // ── Editorial profile card ────────────────────────────────────────────────
  Widget _editorialCard({
    required UserModel user,
    required double width,
    required double height,
    bool showOverlays = false,
  }) {
    final likeOpacity = (_dragOffset.dx / 100).clamp(0.0, 1.0);
    final nopeOpacity = (-_dragOffset.dx / 100).clamp(0.0, 1.0);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.ambient,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Photo fills entire card ─────────────────────────────────
            if (user.photos.isNotEmpty)
              Image.network(
                user.photos[0],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: _avatarColor(user),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => _avatarPlaceholder(user),
              )
            else
              _avatarPlaceholder(user),

            // ── Bottom scrim gradient for text legibility ────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: height * 0.45,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.scrimBottom,
                ),
              ),
            ),

            // ── Profile info overlay at bottom ──────────────────────────
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name + age
                  Text(
                    '${user.firstName}, ${user.age}',
                    style: GoogleFonts.manrope(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Work info
                  if (user.showIndustry && user.industryCategory.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.work_outline_rounded,
                          color: Colors.white.withOpacity(0.8),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            user.industryCategory,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.85),
                              height: 1.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                  if (user.bio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      user.bio,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.75),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // ── LIKE stamp overlay ──────────────────────────────────────
            if (showOverlays)
              Positioned(
                top: 40,
                left: 24,
                child: Opacity(
                  opacity: likeOpacity,
                  child: _stampLabel('LIKE', AppColors.tertiary),
                ),
              ),

            // ── NOPE stamp overlay ──────────────────────────────────────
            if (showOverlays)
              Positioned(
                top: 40,
                right: 24,
                child: Opacity(
                  opacity: nopeOpacity,
                  child: _stampLabel('NOPE', AppColors.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _avatarPlaceholder(UserModel user) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: _avatarColor(user),
      child: Center(
        child: Text(
          user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
          style: GoogleFonts.manrope(
            fontSize: 72,
            fontWeight: FontWeight.w800,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  Widget _stampLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 3),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          color: color,
          fontSize: 28,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  // ── Action buttons — Executive Blush design ───────────────────────────────

  /// Dislike: 64px circle, white bg, close icon in onSurfaceVariant,
  /// ambient shadow, ghost border (outlineVariant at 10%).
  Widget _dislikeButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceContainerLowest,
          border: Border.all(
            color: AppColors.outlineVariant.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: AppShadows.ambient,
        ),
        child: const Icon(
          Icons.close_rounded,
          color: AppColors.onSurfaceVariant,
          size: 28,
        ),
      ),
    );
  }

  /// Super Like: 56px circle, white bg, stars icon (filled) in tertiary
  /// green, ambient shadow.
  Widget _superLikeButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceContainerLowest,
          boxShadow: AppShadows.ambient,
        ),
        child: const Icon(
          Icons.auto_awesome,
          color: AppColors.tertiary,
          size: 24,
        ),
      ),
    );
  }

  /// Like: 64px circle, gradient bg (editorial gradient), white heart icon
  /// (filled), gradient shadow.
  Widget _likeButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.editorialGradient,
          boxShadow: AppShadows.fab,
        ),
        child: const Icon(
          Icons.favorite_rounded,
          color: AppColors.onPrimary,
          size: 28,
        ),
      ),
    );
  }

  // ── Empty state — warm blush tones ────────────────────────────────────────
  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Soft blush icon circle
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
                size: 56,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "You've seen everyone!",
              style: AppTextStyles.headlineSm.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new profiles.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            TextButton.icon(
              onPressed: _loadProfiles,
              icon: const Icon(
                Icons.refresh_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              label: Text(
                'Refresh',
                style: GoogleFonts.manrope(
                  color: AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
