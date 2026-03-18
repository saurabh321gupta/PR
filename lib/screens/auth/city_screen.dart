import 'package:flutter/material.dart';
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
  final String? assetPath; // local asset for enabled cities
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 26),
                color: Colors.black87,
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
                    const Text(
                      'So, which city\ndo you live in?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      'We just want to know so we can show you other amazing people in the same city, right beside you.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
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
                                borderRadius: BorderRadius.circular(16),
                                border: isSelected
                                    ? Border.all(
                                        color: const Color(0xFFE91E63),
                                        width: 3,
                                      )
                                    : null,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    isSelected ? 13 : 16),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // City image or grey placeholder
                                    if (city.enabled &&
                                        city.assetPath != null)
                                      Image.asset(
                                        city.assetPath!,
                                        fit: BoxFit.cover,
                                      )
                                    else
                                      // Grey gradient for disabled cities
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.grey.shade300,
                                              Colors.grey.shade500,
                                            ],
                                          ),
                                        ),
                                      ),

                                    // Bottom gradient overlay for text
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.transparent,
                                            Colors.black
                                                .withValues(alpha: 0.6),
                                            Colors.black
                                                .withValues(alpha: 0.8),
                                          ],
                                          stops: const [0.0, 0.4, 0.75, 1.0],
                                        ),
                                      ),
                                    ),

                                    // City name + country label
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
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              height: 1.2,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'INDIA',
                                            style: TextStyle(
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

                                    // "Coming soon" badge for disabled
                                    if (!city.enabled)
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black
                                                .withValues(alpha: 0.5),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'Coming soon',
                                            style: TextStyle(
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
                                          padding: const EdgeInsets.all(2),
                                          child: const Icon(
                                            Icons.check_circle,
                                            color: Color(0xFFE91E63),
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

            // Bottom CTA — circular arrow
            Padding(
              padding: const EdgeInsets.only(right: 28, bottom: 24),
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selectedCity != null ? _proceed : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: const CircleBorder(),
                      padding: EdgeInsets.zero,
                      elevation: 2,
                    ),
                    child: Icon(
                      Icons.arrow_forward,
                      color: _selectedCity != null
                          ? Colors.white
                          : Colors.grey.shade500,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
