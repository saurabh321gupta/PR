import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
    // Gentle bell swing animation
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

    // Start bell animation after a short delay, then repeat
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
      backgroundColor: Colors.white,
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
                  const Text(
                    'Imagine someone amazing\njust liked your profile...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '...and you never found out. 😬\n\nTurn on notifications so you never miss a match, a message, or that perfect moment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 3),

            // Allow notifications button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _allowNotifications,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Yes, keep me in the loop',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
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
