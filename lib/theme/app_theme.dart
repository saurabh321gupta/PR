import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Grred "Executive Blush" Design System
/// High-end editorial aesthetic for professional dating.

class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFFB0004A);
  static const Color primaryContainer = Color(0xFFD81B60);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Surfaces
  static const Color surface = Color(0xFFFFF8F7);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFFFF0F1);
  static const Color surfaceContainer = Color(0xFFFFE9EB);
  static const Color surfaceContainerHigh = Color(0xFFFFE1E5);
  static const Color surfaceContainerHighest = Color(0xFFF9DBDF);

  // On-surface
  static const Color onSurface = Color(0xFF27171A);
  static const Color onSurfaceVariant = Color(0xFF5A4044);

  // Outline
  static const Color outline = Color(0xFF8E6F74);
  static const Color outlineVariant = Color(0xFFE3BDC3);

  // Tertiary (green accents for super-like, verified)
  static const Color tertiary = Color(0xFF006630);
  static const Color tertiaryContainer = Color(0xFF00823F);

  // Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);

  // Secondary
  static const Color secondary = Color(0xFFA33855);
  static const Color secondaryContainer = Color(0xFFFC7E9A);
  static const Color secondaryFixedDim = Color(0xFFFFB2BF);

  // Gradients
  static const LinearGradient editorialGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryContainer],
  );

  static const LinearGradient scrimBottom = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [Color(0xCC27171A), Color(0x0027171A)],
  );
}

class AppTextStyles {
  AppTextStyles._();

  // Headlines — Manrope
  static TextStyle displayLg = GoogleFonts.manrope(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.onSurface,
  );

  static TextStyle headlineLg = GoogleFonts.manrope(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
    color: AppColors.onSurface,
  );

  static TextStyle headlineMd = GoogleFonts.manrope(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
  );

  static TextStyle headlineSm = GoogleFonts.manrope(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
  );

  // Body — Inter
  static TextStyle bodyLg = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.6,
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle bodyMd = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.5,
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle bodySm = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
  );

  // Labels — Inter
  static TextStyle labelLg = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.onSurface,
  );

  static TextStyle labelMd = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle labelSm = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: AppColors.onSurfaceVariant,
  );

  // Brand
  static TextStyle brand = GoogleFonts.manrope(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
    color: AppColors.primary,
  );

  // Section headers (uppercase small)
  static TextStyle sectionHeader = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 2.0,
    color: AppColors.primary,
  );
}

/// Shared ambient shadow (no harsh Material shadows)
class AppShadows {
  AppShadows._();

  static List<BoxShadow> ambient = [
    const BoxShadow(
      color: Color(0x0F27171A), // 6% opacity
      blurRadius: 32,
      offset: Offset.zero,
    ),
  ];

  static List<BoxShadow> card = [
    const BoxShadow(
      color: Color(0x0A27171A), // ~4% opacity
      blurRadius: 24,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> fab = [
    const BoxShadow(
      color: Color(0x4DB0004A), // 30% primary opacity
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}

/// Shared border radius values
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 48;
  static const double full = 9999;
}
