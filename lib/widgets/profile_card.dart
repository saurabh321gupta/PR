import 'package:flutter/material.dart';
import '../models/user_model.dart';

class ProfileCard extends StatelessWidget {
  final UserModel user;
  final Offset dragOffset;
  final bool isTop; // only the top card is draggable
  final VoidCallback? onMoreTap;

  const ProfileCard({
    super.key,
    required this.user,
    this.dragOffset = Offset.zero,
    this.isTop = false,
    this.onMoreTap,
  });

  // Like/Nope opacity based on horizontal drag
  double get _likeOpacity => (dragOffset.dx / 100).clamp(0.0, 1.0);
  double get _nopeOpacity => (-dragOffset.dx / 100).clamp(0.0, 1.0);

  // Avatar background colour based on name initial
  Color _avatarColor() {
    final colors = [
      Colors.pink.shade300,
      Colors.purple.shade300,
      Colors.indigo.shade300,
      Colors.teal.shade400,
      Colors.orange.shade400,
      Colors.deepPurple.shade300,
    ];
    final index = user.firstName.isNotEmpty
        ? user.firstName.codeUnitAt(0) % colors.length
        : 0;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final rotation = isTop ? dragOffset.dx * 0.0015 : 0.0;

    return Transform.translate(
      offset: isTop ? dragOffset : Offset.zero,
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          width: screenSize.width - 32,
          height: screenSize.height * 0.68,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // ── Avatar / photo area ──────────────────────────────────
                Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: user.photos.isNotEmpty
                          ? Image.network(
                              user.photos[0],
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (_, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: _avatarColor(),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => _avatarPlaceholder(),
                            )
                          : _avatarPlaceholder(),
                    ),

                    // ── Profile info ───────────────────────────────────────
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${user.firstName}, ${user.age}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Verified badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.green.shade300),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified,
                                          size: 13,
                                          color: Colors.green.shade600),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Verified',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 6),

                            // Industry / role (optional display)
                            if (user.showIndustry &&
                                user.industryCategory.isNotEmpty)
                              Text(
                                user.industryCategory,
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey.shade600),
                              ),

                            const SizedBox(height: 10),

                            // Bio
                            Expanded(
                              child: Text(
                                user.bio,
                                style: const TextStyle(
                                    fontSize: 14, height: 1.5),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // ── LIKE overlay ────────────────────────────────────────
                if (isTop)
                  Positioned(
                    top: 40,
                    left: 24,
                    child: Opacity(
                      opacity: _likeOpacity,
                      child: _stampLabel('LIKE', Colors.green),
                    ),
                  ),

                // ── NOPE overlay ────────────────────────────────────────
                if (isTop)
                  Positioned(
                    top: 40,
                    right: 24,
                    child: Opacity(
                      opacity: _nopeOpacity,
                      child: _stampLabel('NOPE', Colors.red),
                    ),
                  ),

                // ── More (⋮) button ──────────────────────────────────────
                if (isTop && onMoreTap != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: onMoreTap,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.more_vert,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      width: double.infinity,
      color: _avatarColor(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white.withOpacity(0.3),
            child: Text(
              user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stampLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 28,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
