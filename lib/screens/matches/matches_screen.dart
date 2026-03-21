import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';
import '../chat/chat_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final _chatService = ChatService();
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  late final Stream<List<MatchWithUser>> _matchesStream;

  @override
  void initState() {
    super.initState();
    _matchesStream = _chatService.matchesStream(_currentUserId);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'NOW';
    if (diff.inMinutes < 60) return '${diff.inMinutes}M AGO';
    if (diff.inHours < 24) return '${diff.inHours}H AGO';
    return '${diff.inDays}D AGO';
  }

  Color _avatarColor(String name) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.primaryContainer,
      AppColors.tertiary,
      AppColors.outline,
    ];
    final index = name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0;
    return colors[index];
  }

  void _navigateToChat(MatchWithUser match) async {
    // Mark as read when opening chat
    _chatService.markAsRead(
      matchId: match.matchId,
      userId: _currentUserId,
    );
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          matchId: match.matchId,
          otherUser: match.otherUser,
        ),
      ),
    );
    // Mark as read again on return (in case new messages came while chatting)
    _chatService.markAsRead(
      matchId: match.matchId,
      userId: _currentUserId,
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: StreamBuilder<List<MatchWithUser>>(
        stream: _matchesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }
          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          }

          final matches = snapshot.data ?? [];
          if (matches.isEmpty) return _buildEmpty();

          // Split: new matches (no messages yet) vs conversations
          final newMatches =
              matches.where((m) => m.lastMessage == null).toList();
          final conversations =
              matches.where((m) => m.lastMessage != null).toList();

          return Stack(
            children: [
              // ── Scrollable content (real-time via stream) ──
              ListView(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 60,
                    bottom: 40,
                  ),
                  children: [
                    // Page header
                    _buildPageHeader(),

                    // New matches section
                    if (newMatches.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      _buildSectionHeader('NEW MATCHES'),
                      const SizedBox(height: 16),
                      _buildNewMatchesRow(newMatches),
                    ],

                    // Conversations section
                    if (conversations.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      _buildSectionHeader('CONVERSATIONS'),
                      const SizedBox(height: 16),
                      _buildConversationsList(conversations),
                    ],

                    // If we have new matches but no conversations
                    if (conversations.isEmpty && newMatches.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      _buildSectionHeader('CONVERSATIONS'),
                      const SizedBox(height: 48),
                      Center(
                        child: Text(
                          'Start a conversation!',
                          style: AppTextStyles.bodyMd,
                        ),
                      ),
                    ],
                  ],
              ),

              // ── Glassmorphic header ──
              _buildGlassHeader(context),
            ],
          );
        },
      ),
    );
  }

  // ── Glass Header ─────────────────────────────────────────────────────────

  Widget _buildGlassHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.80),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.outlineVariant.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
            ),
            padding: EdgeInsets.only(
              top: topPadding + 8,
              bottom: 12,
              left: 20,
              right: 20,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.menu_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                const Spacer(),
                Text('Grred', style: AppTextStyles.brand),
                const Spacer(),
                // Balance the row with an invisible icon
                const SizedBox(width: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Page Header ──────────────────────────────────────────────────────────

  Widget _buildPageHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('Messages', style: AppTextStyles.displayLg),
          const SizedBox(height: 4),
          Text(
            'Your curated connections',
            style: AppTextStyles.bodyMd,
          ),
        ],
      ),
    );
  }

  // ── Section Header ───────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(title, style: AppTextStyles.sectionHeader),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.outlineVariant.withOpacity(0.20),
            ),
          ),
        ],
      ),
    );
  }

  // ── New Matches Row ──────────────────────────────────────────────────────

  Widget _buildNewMatchesRow(List<MatchWithUser> newMatches) {
    return SizedBox(
      height: 100,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: newMatches.length,
          itemBuilder: (context, index) {
            final match = newMatches[index];
            final user = match.otherUser;
            final hasPhoto = user.photos.isNotEmpty;
            return GestureDetector(
              onTap: () => _navigateToChat(match),
              child: Padding(
                padding: EdgeInsets.only(
                  right: index < newMatches.length - 1 ? 16 : 0,
                ),
                child: Column(
                  children: [
                    // Ring + avatar
                    Container(
                      width: 72,
                      height: 72,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: hasPhoto
                            ? Image.network(
                                user.photos.first,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildAvatarFallback(user, isCircle: true),
                              )
                            : _buildAvatarFallback(user, isCircle: true),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.firstName,
                      style: AppTextStyles.labelMd.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Conversations List ───────────────────────────────────────────────────

  Widget _buildConversationsList(List<MatchWithUser> conversations) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: List.generate(conversations.length, (index) {
          final match = conversations[index];
          final isOdd = index % 2 == 0; // 0-indexed: first item is "odd"
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < conversations.length - 1 ? 24 : 0,
            ),
            child: _ConversationCard(
              match: match,
              isElevated: isOdd,
              isFirst: index == 0,
              timeAgo: _timeAgo(match.lastMessageAt),
              avatarColor: _avatarColor(match.otherUser.firstName),
              onTap: () => _navigateToChat(match),
            ),
          );
        }),
      ),
    );
  }

  // ── Avatar Fallback ──────────────────────────────────────────────────────

  Widget _buildAvatarFallback(dynamic user, {bool isCircle = false}) {
    final color = _avatarColor(user.firstName);
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(AppRadius.md),
      ),
      alignment: Alignment.center,
      child: Text(
        user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
        style: GoogleFonts.manrope(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ── Loading State ────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Stack(
      children: [
        Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
        _buildGlassHeader(context),
      ],
    );
  }

  // ── Error State ──────────────────────────────────────────────────────────

  Widget _buildError(String error) {
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: AppTextStyles.headlineSm,
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  style: AppTextStyles.bodyMd,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        _buildGlassHeader(context),
      ],
    );
  }

  // ── Empty State ──────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.primary,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No matches yet',
                  style: AppTextStyles.headlineMd,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Keep swiping \u2014 your matches will appear here.',
                  style: AppTextStyles.bodyMd,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        _buildGlassHeader(context),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// Conversation Card
// ════════════════════════════════════════════════════════════════════════════════

class _ConversationCard extends StatelessWidget {
  final MatchWithUser match;
  final bool isElevated; // true = white with shadow, false = blush no shadow
  final bool isFirst;
  final String timeAgo;
  final Color avatarColor;
  final VoidCallback onTap;

  const _ConversationCard({
    required this.match,
    required this.isElevated,
    required this.isFirst,
    required this.timeAgo,
    required this.avatarColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = match.otherUser;
    final hasPhoto = user.photos.isNotEmpty;

    final isUnread = match.isUnread;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isElevated
              ? AppColors.surfaceContainerLowest
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: isElevated ? AppShadows.card : null,
        ),
        child: Row(
          children: [
            // ── Avatar with optional online indicator ──
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Avatar (rounded rectangle)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: hasPhoto
                        ? Image.network(
                            user.photos.first,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildCardAvatar(user),
                          )
                        : _buildCardAvatar(user),
                  ),
                  // Online indicator (only for first/active chat)
                  if (isFirst)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surfaceContainerLowest,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // ── Text content ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + timestamp row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          user.firstName,
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timeAgo.isNotEmpty)
                        Text(
                          timeAgo,
                          style: AppTextStyles.labelSm.copyWith(
                            letterSpacing: 1.5,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Message preview
                  Text(
                    match.lastMessage ?? 'Say hi!',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: match.lastMessage != null
                          ? AppColors.onSurfaceVariant
                          : AppColors.outline,
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

            // ── Unread dot ──
            if (isUnread) ...[
              const SizedBox(width: 12),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardAvatar(dynamic user) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: avatarColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      alignment: Alignment.center,
      child: Text(
        user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
        style: GoogleFonts.manrope(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: avatarColor,
        ),
      ),
    );
  }
}
