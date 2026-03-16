import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class ProfileDetailScreen extends StatelessWidget {
  final UserModel user;
  final VoidCallback onLike;
  final VoidCallback onPass;

  const ProfileDetailScreen({
    super.key,
    required this.user,
    required this.onLike,
    required this.onPass,
  });

  Color _avatarColor() {
    final colors = [
      Colors.pink.shade300,
      Colors.purple.shade300,
      Colors.indigo.shade300,
      Colors.teal.shade400,
      Colors.orange.shade400,
      Colors.deepPurple.shade300,
    ];
    return colors[user.firstName.isNotEmpty
        ? user.firstName.codeUnitAt(0) % colors.length
        : 0];
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Scrollable profile content ───────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Photo ────────────────────────────────────────────────
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  width: double.infinity,
                  child: user.photos.isNotEmpty
                      ? Image.network(
                          user.photos[0],
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: _avatarColor(),
                              child: const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => _avatarFallback(),
                        )
                      : _avatarFallback(),
                ),

                // ── Info section ─────────────────────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + age
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '${user.firstName}, ${user.age}',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Verified badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified,
                                    size: 14, color: Colors.green.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  'Verified Professional',
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

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Bio
                      if (user.bio.isNotEmpty) ...[
                        _sectionLabel('About'),
                        const SizedBox(height: 8),
                        Text(
                          user.bio,
                          style: const TextStyle(
                              fontSize: 15, height: 1.6, color: Colors.black87),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Industry (if shown)
                      if (user.showIndustry &&
                          user.industryCategory.isNotEmpty) ...[
                        _infoChip(
                            Icons.work_outline, user.industryCategory),
                        const SizedBox(height: 10),
                      ],

                      // Role (if shown)
                      if (user.showRole && user.role.isNotEmpty) ...[
                        _infoChip(Icons.badge_outlined, user.role),
                        const SizedBox(height: 10),
                      ],

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Back button ──────────────────────────────────────────────
          Positioned(
            top: topPad + 12,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 18),
              ),
            ),
          ),

          // ── Bottom action bar ────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 48,
                right: 48,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -4)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Pass button
                  _actionBtn(
                    icon: Icons.close,
                    color: Colors.red.shade400,
                    size: 60,
                    onTap: () {
                      Navigator.pop(context);
                      onPass();
                    },
                  ),

                  // Like button
                  _actionBtn(
                    icon: Icons.favorite,
                    color: Colors.pink,
                    size: 68,
                    onTap: () {
                      Navigator.pop(context);
                      onLike();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      color: _avatarColor(),
      child: Center(
        child: Text(
          user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 96,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade500,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _actionBtn({
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
              blurRadius: 14,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.45),
      ),
    );
  }
}
