import 'package:flutter/material.dart';
import 'dart:ui';
import 'swipe/swipe_screen.dart';
import 'matches/matches_screen.dart';
import 'profile/profile_screen.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    SwipeScreen(),
    MatchesScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Init notifications after user is confirmed signed in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      extendBody: true,
      bottomNavigationBar: _GlassmorphicBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
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
  final ValueChanged<int> onTap;

  const _GlassmorphicBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          const BoxShadow(
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
              color: AppColors.surface.withOpacity(0.9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(48),
                topRight: Radius.circular(48),
              ),
              border: Border(
                top: BorderSide(
                  color: AppColors.outlineVariant.withOpacity(0.15),
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
                  return _NavTabItem(
                    tab: _tabs[index],
                    isActive: isActive,
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
  final VoidCallback onTap;

  const _NavTabItem({
    required this.tab,
    required this.isActive,
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
          child: AnimatedContainer(
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
        ),
      ),
    );
  }
}
