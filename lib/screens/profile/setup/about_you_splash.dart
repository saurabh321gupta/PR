import 'package:flutter/material.dart';
import 'name_birthday_screen.dart';

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
  late Animation<double> _fadeAnim;
  late Animation<double> _scalePulse;

  @override
  void initState() {
    super.initState();

    // Fade in
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Gentle scale pulse on the emoji
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scalePulse = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _scaleController.forward().then((_) {
          if (mounted) _scaleController.reverse();
        });
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
                // Animated emoji
                ScaleTransition(
                  scale: _scalePulse,
                  child: const Text(
                    '🪄',
                    style: TextStyle(fontSize: 64),
                  ),
                ),

                const SizedBox(height: 28),

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
