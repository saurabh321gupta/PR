import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'swipe/swipe_screen.dart';
import 'matches/matches_screen.dart';
import 'profile/profile_screen.dart';
import '../services/chat_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _hasUnread = false;

  final List<Widget> _screens = const [
    SwipeScreen(),
    MatchesScreen(),
    ProfileScreen(),
  ];

  final _chatService = ChatService();
  StreamSubscription<List<MatchWithUser>>? _matchesSub;

  @override
  void initState() {
    super.initState();
    // Init notifications after user is confirmed signed in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.init();
    });
    _listenForUnread();
  }

  void _listenForUnread() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _matchesSub = _chatService.matchesStream(uid).listen((matches) {
      final hasUnread = matches.any((m) => m.isUnread);
      if (hasUnread != _hasUnread) {
        setState(() => _hasUnread = hasUnread);
      }
    });
  }

  @override
  void dispose() {
    _matchesSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // PopScope prevents the system back button from popping past _AuthGate.
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        extendBody: true,
        bottomNavigationBar: _GlassmorphicBottomNav(
          currentIndex: _currentIndex,
          hasUnreadMessages: _hasUnread,
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }
}

/// Tab definition holding icon pairs for active/inactive states.
class _NavTab {
  final IconData icon;
  final IconData activeIcon;

  const _NavTab({required this.icon, required this.activeIcon});
}

const List<_NavTab> _tabs = [
  _NavTab(icon: Icons.style_outlined, activeIcon: Icons.style),
  _NavTab(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble),
  _NavTab(icon: Icons.person_outline, activeIcon: Icons.person),
];

class _GlassmorphicBottomNav extends StatelessWidget {
  final int currentIndex;
  final bool hasUnreadMessages;
  final ValueChanged<int> onTap;

  const _GlassmorphicBottomNav({
    required this.currentIndex,
    required this.hasUnreadMessages,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x0F27171A),
            blurRadius: 32,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(48),
          topRight: Radius.circular(48),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(48),
                topRight: Radius.circular(48),
              ),
              border: Border(
                top: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
            ),
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: SizedBox(
              height: 72,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_tabs.length, (index) {
                  final isActive = index == currentIndex;
                  // Messages tab is index 1
                  final showDot = index == 1 && hasUnreadMessages;
                  return _NavTabItem(
                    tab: _tabs[index],
                    isActive: isActive,
                    showBadge: showDot,
                    onTap: () => onTap(index),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTabItem extends StatelessWidget {
  final _NavTab tab;
  final bool isActive;
  final bool showBadge;
  final VoidCallback onTap;

  const _NavTabItem({
    required this.tab,
    required this.isActive,
    this.showBadge = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        height: 64,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: 48,
                height: 48,
                decoration: isActive
                    ? BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFB0004A),
                            Color(0xFFD81B60),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.fab,
                      )
                    : null,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isActive ? tab.activeIcon : tab.icon,
                      key: ValueKey(isActive),
                      size: 24,
                      color: isActive
                          ? AppColors.onPrimary
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              // Unread dot
              if (showBadge)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444), // red-500
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surface,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
