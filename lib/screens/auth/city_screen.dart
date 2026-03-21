import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'notification_screen.dart';

class CityScreen extends StatefulWidget {
  final String userId;
  final String workEmail;

  const CityScreen({
    super.key,
    required this.userId,
    required this.workEmail,
  });

  @override
  State<CityScreen> createState() => _CityScreenState();
}

class _CityItem {
  final String name;
  final String? assetPath;
  final bool enabled;

  const _CityItem({
    required this.name,
    this.assetPath,
    this.enabled = false,
  });
}

class _CityScreenState extends State<CityScreen> {
  String? _selectedCity;

  static const List<_CityItem> _cities = [
    _CityItem(
      name: 'Bangalore',
      assetPath: 'assets/cities/bangalore.jpg',
      enabled: true,
    ),
    _CityItem(name: 'Pune'),
    _CityItem(name: 'Hyderabad'),
    _CityItem(name: 'Chennai'),
    _CityItem(name: 'Delhi-NCR'),
  ];

  void _proceed() {
    if (_selectedCity == null) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationScreen(
          userId: widget.userId,
          workEmail: widget.workEmail,
          city: _selectedCity!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 24),
                color: AppColors.onSurface,
                splashRadius: 22,
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // Heading
                    Text(
                      'So, which city\ndo you live in?',
                      style: AppTextStyles.headlineLg.copyWith(height: 1.25),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      'We just want to know so we can show you other amazing people in the same city, right beside you.',
                      style: AppTextStyles.bodyLg,
                    ),

                    const SizedBox(height: 28),

                    // City tiles grid
                    Expanded(
                      child: GridView.builder(
                        padding: EdgeInsets.zero,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.9,
                        ),
                        itemCount: _cities.length,
                        itemBuilder: (context, index) {
                          final city = _cities[index];
                          final isSelected = _selectedCity == city.name;

                          return GestureDetector(
                            onTap: city.enabled
                                ? () {
                                    setState(
                                        () => _selectedCity = city.name);
                                  }
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                border: isSelected
                                    ? Border.all(
                                        color: AppColors.primary,
                                        width: 3,
                                      )
                                    : null,
                                boxShadow: isSelected
                                    ? AppShadows.card
                                    : null,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    isSelected ? 13 : AppRadius.md),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // City image or blush placeholder
                                    if (city.enabled &&
                                        city.assetPath != null)
                                      Image.asset(
                                        city.assetPath!,
                                        fit: BoxFit.cover,
                                      )
                                    else
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              AppColors.surfaceContainerHigh,
                                              AppColors.surfaceContainerHighest,
                                            ],
                                          ),
                                        ),
                                      ),

                                    // Bottom scrim gradient
                                    Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.transparent,
                                            Color(0x9927171A),
                                            Color(0xCC27171A),
                                          ],
                                          stops: [0.0, 0.4, 0.75, 1.0],
                                        ),
                                      ),
                                    ),

                                    // City name + country
                                    Positioned(
                                      left: 14,
                                      bottom: 14,
                                      right: 14,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            city.name,
                                            style: GoogleFonts.manrope(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              height: 1.2,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'INDIA',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white
                                                  .withValues(alpha: 0.75),
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // "Coming soon" badge
                                    if (!city.enabled)
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.onSurface
                                                .withValues(alpha: 0.5),
                                            borderRadius:
                                                BorderRadius.circular(
                                                    AppRadius.sm),
                                          ),
                                          child: Text(
                                            'Coming soon',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),

                                    // Checkmark for selected
                                    if (isSelected)
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          padding:
                                              const EdgeInsets.all(2),
                                          child: Icon(
                                            Icons.check_circle,
                                            color: AppColors.primary,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom CTA — gradient circular button
            Padding(
              padding: const EdgeInsets.only(right: 28, bottom: 24),
              child: Align(
                alignment: Alignment.centerRight,
                child: _buildCtaButton(
                  onPressed: _selectedCity != null ? _proceed : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCtaButton({required VoidCallback? onPressed}) {
    final enabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: enabled ? AppColors.editorialGradient : null,
          color: enabled ? null : AppColors.outlineVariant,
          shape: BoxShape.circle,
          boxShadow: enabled ? AppShadows.fab : null,
        ),
        child: Center(
          child: Icon(
            Icons.arrow_forward_rounded,
            color: enabled ? Colors.white : AppColors.outline,
            size: 26,
          ),
        ),
      ),
    );
  }
}
