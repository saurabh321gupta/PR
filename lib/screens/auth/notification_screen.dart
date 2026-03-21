import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../profile/setup/about_you_splash.dart';

class NotificationScreen extends StatefulWidget {
  final String userId;
  final String workEmail;
  final String city;

  const NotificationScreen({
    super.key,
    required this.userId,
    required this.workEmail,
    required this.city,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bellController;
  late Animation<double> _bellAnimation;

  @override
  void initState() {
    super.initState();
    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _bellAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: 0.15)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 1),
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.15, end: -0.12)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 1),
      TweenSequenceItem(
          tween: Tween<double>(begin: -0.12, end: 0.08)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 1),
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.08, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 1),
    ]).animate(_bellController);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _ringBell();
    });
  }

  void _ringBell() {
    _bellController.forward(from: 0).then((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _ringBell();
      });
    });
  }

  @override
  void dispose() {
    _bellController.dispose();
    super.dispose();
  }

  void _goToProfileSetup() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AboutYouSplash(
          userId: widget.userId,
          workEmail: widget.workEmail,
          city: widget.city,
        ),
      ),
    );
  }

  Future<void> _allowNotifications() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (!mounted) return;
    _goToProfileSetup();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),

            // Animated bell
            AnimatedBuilder(
              animation: _bellAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _bellAnimation.value,
                  child: child,
                );
              },
              child: const Text(
                '🔔',
                style: TextStyle(fontSize: 72),
              ),
            ),

            const SizedBox(height: 36),

            // Heading
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                children: [
                  Text(
                    'Imagine someone amazing\njust liked your profile...',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineMd.copyWith(height: 1.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '...and you never found out. 😬\n\nTurn on notifications so you never miss a match, a message, or that perfect moment.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyLg.copyWith(height: 1.6),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 3),

            // Allow notifications button — gradient pill
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: GestureDetector(
                onTap: _allowNotifications,
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: AppColors.editorialGradient,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    boxShadow: AppShadows.fab,
                  ),
                  child: Center(
                    child: Text(
                      'Yes, keep me in the loop',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Skip
            GestureDetector(
              onTap: _goToProfileSetup,
              child: Text(
                'I like living dangerously — skip',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.outline,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
