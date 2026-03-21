import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'name_birthday_screen.dart';

// ── Custom 4-point sparkle/diamond painter ──────────────────────

class _SparklePainter extends CustomPainter {
  final Color color;
  final double glowOpacity;

  _SparklePainter({required this.color, this.glowOpacity = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Outer glow
    if (glowOpacity > 0) {
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: glowOpacity * 0.3),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: size.width * 0.5));
      canvas.drawCircle(Offset(cx, cy), size.width * 0.5, glowPaint);
    }

    // Main diamond shape — 4-point star
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color,
          color.withValues(alpha: 0.7),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(cx, cy - size.height * 0.45) // Top point
      ..quadraticBezierTo(cx + size.width * 0.08, cy - size.height * 0.08, cx + size.width * 0.45, cy) // Right
      ..quadraticBezierTo(cx + size.width * 0.08, cy + size.height * 0.08, cx, cy + size.height * 0.45) // Bottom
      ..quadraticBezierTo(cx - size.width * 0.08, cy + size.height * 0.08, cx - size.width * 0.45, cy) // Left
      ..quadraticBezierTo(cx - size.width * 0.08, cy - size.height * 0.08, cx, cy - size.height * 0.45) // Back to top
      ..close();
    canvas.drawPath(path, fillPaint);

    // Highlight streak
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.03
      ..strokeCap = StrokeCap.round;

    final hlPath = Path()
      ..moveTo(cx - size.width * 0.08, cy - size.height * 0.25)
      ..quadraticBezierTo(cx - size.width * 0.02, cy - size.height * 0.1, cx - size.width * 0.2, cy);
    canvas.drawPath(hlPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.glowOpacity != glowOpacity;
}

// ── Screen ──────────────────────────────────────────────────────

class AboutYouSplash extends StatefulWidget {
  final String userId;
  final String workEmail;
  final String city;

  const AboutYouSplash({
    super.key,
    required this.userId,
    required this.workEmail,
    required this.city,
  });

  @override
  State<AboutYouSplash> createState() => _AboutYouSplashState();
}

class _AboutYouSplashState extends State<AboutYouSplash>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _rotateController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scalePulse;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();

    // Fade in everything
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    // Scale pulse on the sparkle
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scalePulse = Tween<double>(begin: 0.85, end: 1.1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Glow pulse
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Slow rotation
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Orchestrate
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _scaleController.forward().then((_) {
          if (mounted) _scaleController.reverse();
        });
        _glowController.forward().then((_) {
          if (mounted) _glowController.reverse();
        });
        _rotateController.animateTo(0.08, curve: Curves.easeInOut);
      }
    });

    // Auto-navigate after 2 seconds
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a1, a2) => NameBirthdayScreen(
            userId: widget.userId,
            workEmail: widget.workEmail,
            city: widget.city,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                )),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _glowController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated sparkle icon
                AnimatedBuilder(
                  animation: Listenable.merge([_scaleController, _glowController, _rotateController]),
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotateController.value * math.pi * 2,
                      child: Transform.scale(
                        scale: _scalePulse.value,
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: CustomPaint(
                            painter: _SparklePainter(
                              color: const Color(0xFFE91E63),
                              glowOpacity: _glowAnim.value,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Main text
                const Text(
                  'Your story starts\nhere',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 14),

                // Subtitle
                Text(
                  'Let\'s build a profile that\'s\nimpossible to swipe left on.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
