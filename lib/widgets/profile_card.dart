import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';

class ProfileCard extends StatelessWidget {
  final UserModel user;
  final Offset dragOffset;
  final bool isTop;
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
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.card,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // -- Full-bleed photo / fallback --------------------------
                _buildPhoto(),

                // -- Bottom scrim gradient --------------------------------
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: screenSize.height * 0.68 * 0.40,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.scrimBottom,
                    ),
                  ),
                ),

                // -- Profile info overlay ---------------------------------
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 24,
                  child: _buildProfileInfo(),
                ),

                // -- LIKE stamp -------------------------------------------
                if (isTop)
                  Positioned(
                    top: 40,
                    left: 24,
                    child: Opacity(
                      opacity: _likeOpacity,
                      child: _stampLabel('LIKE', AppColors.tertiary),
                    ),
                  ),

                // -- NOPE stamp -------------------------------------------
                if (isTop)
                  Positioned(
                    top: 40,
                    right: 24,
                    child: Opacity(
                      opacity: _nopeOpacity,
                      child: _stampLabel('NOPE', AppColors.error),
                    ),
                  ),

                // -- More button ------------------------------------------
                if (isTop && onMoreTap != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: onMoreTap,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.onSurface.withOpacity(0.35),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                          size: 20,
                        ),
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

  // ── Full-bleed photo or avatar fallback ──────────────────────────────────

  Widget _buildPhoto() {
    if (user.photos.isNotEmpty) {
      return Image.network(
        user.photos[0],
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            color: AppColors.surfaceContainerHigh,
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.onSurfaceVariant,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _avatarPlaceholder(),
      );
    }
    return _avatarPlaceholder();
  }

  // ── Avatar fallback: surfaceContainerHigh bg + onSurfaceVariant initial ──

  Widget _avatarPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.surfaceContainerHigh,
      child: Center(
        child: Text(
          user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
          style: GoogleFonts.manrope(
            fontSize: 72,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  // ── Profile info overlay (over scrim) ────────────────────────────────────

  Widget _buildProfileInfo() {
    // Build the work string: "Role, City" or whichever parts are available
    final workParts = <String>[
      if (user.showRole && user.role.isNotEmpty) user.role,
      if (user.city.isNotEmpty) user.city,
    ];
    final workText = workParts.join(', ');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // -- Name + age + verified badge --------------------------------
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                '${user.firstName}, ${user.age}',
                style: GoogleFonts.manrope(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.verified,
              size: 22,
              color: AppColors.secondaryFixedDim,
            ),
          ],
        ),

        // -- Work info row ----------------------------------------------
        if (workText.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.work_outline,
                size: 14,
                color: Colors.white.withOpacity(0.90),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  workText,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.90),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],

        // -- Bio preview ------------------------------------------------
        if (user.bio.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            user.bio,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.6,
              color: Colors.white.withOpacity(0.85),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  // ── LIKE / NOPE stamp labels ─────────────────────────────────────────────

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
}
