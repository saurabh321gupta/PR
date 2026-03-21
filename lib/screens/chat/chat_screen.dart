import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';
import '../swipe/profile_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  final String matchId;
  final UserModel otherUser;

  const ChatScreen({
    super.key,
    required this.matchId,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Mark as read when opening chat
    _chatService.markAsRead(
      matchId: widget.matchId,
      userId: _currentUserId,
    );
  }

  @override
  void dispose() {
    // Mark as read on close too (catches messages that came while viewing)
    _chatService.markAsRead(
      matchId: widget.matchId,
      userId: _currentUserId,
    );
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    await _chatService.sendMessage(
      matchId: widget.matchId,
      senderId: _currentUserId,
      text: text,
    );

    // Also mark as read — we just sent, so we've seen everything
    _chatService.markAsRead(
      matchId: widget.matchId,
      userId: _currentUserId,
    );

    setState(() => _isSending = false);
    _scrollToBottom();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // ── Messages + input ──
          Column(
            children: [
              SizedBox(height: topPadding + 72), // space for glass header
              Expanded(child: _buildMessageList()),
              _buildInputBar(),
            ],
          ),

          // ── Glassmorphic header ──
          _buildGlassHeader(topPadding),
        ],
      ),
    );
  }

  // ── Glass Header ───────────────────────────────────────────────────────────

  Widget _buildGlassHeader(double topPadding) {
    final user = widget.otherUser;
    final hasPhoto = user.photos.isNotEmpty;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withAlpha(204), // 80%
              border: Border(
                bottom: BorderSide(
                  color: AppColors.outlineVariant.withAlpha(51), // 20%
                  width: 0.5,
                ),
              ),
            ),
            padding: EdgeInsets.only(
              top: topPadding + 8,
              bottom: 12,
              left: 4,
              right: 12,
            ),
            child: Row(
              children: [
                // Back button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),

                // Avatar
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ProfileDetailScreen(user: widget.otherUser),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: hasPhoto
                          ? Image.network(
                              user.photos[0],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _avatarFallback(user),
                            )
                          : _avatarFallback(user),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProfileDetailScreen(user: widget.otherUser),
                      ),
                    ),
                    child: Text(
                      user.firstName,
                      style: GoogleFonts.manrope(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // Video call placeholder
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.videocam_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback(UserModel user) {
    return Container(
      color: AppColors.surfaceContainerHigh,
      alignment: Alignment.center,
      child: Text(
        user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
        style: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }

  // ── Message List ───────────────────────────────────────────────────────────

  Widget _buildMessageList() {
    return StreamBuilder<List<ChatMessage>>(
      stream: _chatService.messagesStream(widget.matchId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          );
        }

        final messages = snapshot.data ?? [];

        if (messages.isEmpty) return _buildEmptyChat();

        // Mark as read whenever new messages arrive
        _chatService.markAsRead(
          matchId: widget.matchId,
          userId: _currentUserId,
        );

        _scrollToBottom();

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            final isMe = msg.senderId == _currentUserId;

            // Date separator
            final showDate = index == 0 ||
                !_sameDay(messages[index - 1].createdAt, msg.createdAt);

            return Column(
              children: [
                if (showDate) _dateSeparator(msg.createdAt),
                _MessageBubble(message: msg, isMe: isMe),
              ],
            );
          },
        );
      },
    );
  }

  Widget _dateSeparator(DateTime dt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 0.5,
              color: AppColors.outlineVariant.withAlpha(64),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatDate(dt),
              style: AppTextStyles.labelSm.copyWith(
                letterSpacing: 1.5,
                color: AppColors.outline,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 0.5,
              color: AppColors.outlineVariant.withAlpha(64),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.favorite_rounded,
              color: AppColors.primary,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You matched with ${widget.otherUser.firstName}!',
            style: AppTextStyles.headlineSm,
          ),
          const SizedBox(height: 6),
          Text(
            'Say something nice :)',
            style: AppTextStyles.bodyMd,
          ),
        ],
      ),
    );
  }

  // ── Input Bar ──────────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withAlpha(38), // 15%
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
                style: AppTextStyles.bodyLg.copyWith(
                  color: AppColors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message\u2026',
                  hintStyle: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.outline,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.editorialGradient,
                  shape: BoxShape.circle,
                  boxShadow: _isSending ? null : AppShadows.fab,
                ),
                child: _isSending
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (_sameDay(dt, now)) return 'TODAY';
    if (_sameDay(dt, now.subtract(const Duration(days: 1)))) return 'YESTERDAY';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// Message Bubble — Executive Blush style
// ════════════════════════════════════════════════════════════════════════════════

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          // Sent: editorial gradient, Received: white card
          gradient: isMe ? AppColors.editorialGradient : null,
          color: isMe ? null : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: GoogleFonts.inter(
                fontSize: 15,
                height: 1.5,
                color: isMe ? Colors.white : AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isMe
                    ? Colors.white.withAlpha(179) // 70%
                    : AppColors.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
