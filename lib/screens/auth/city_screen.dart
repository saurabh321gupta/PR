import 'package:flutter/material.dart';
import '../profile/profile_setup_screen.dart';

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
  final String emoji;
  final bool enabled;

  const _CityItem({
    required this.name,
    required this.emoji,
    this.enabled = false,
  });
}

class _CityScreenState extends State<CityScreen> {
  String? _selectedCity;

  static const List<_CityItem> _cities = [
    _CityItem(name: 'Bangalore', emoji: '🏙️', enabled: true),
    _CityItem(name: 'Pune', emoji: '🌆'),
    _CityItem(name: 'Hyderabad', emoji: '🕌'),
    _CityItem(name: 'Chennai', emoji: '🏛️'),
    _CityItem(name: 'Delhi-NCR', emoji: '🏰'),
  ];

  void _proceed() {
    if (_selectedCity == null) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileSetupScreen(
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

                    const SizedBox(height: 32),

                    // City tiles grid
                    Expanded(
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 1.3,
                        ),
                        itemCount: _cities.length,
                        itemBuilder: (context, index) {
                          final city = _cities[index];
                          final isSelected = _selectedCity == city.name;

                          return GestureDetector(
                            onTap: city.enabled
                                ? () {
                                    setState(() => _selectedCity = city.name);
                                  }
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFFCE4EC)
                                    : city.enabled
                                        ? Colors.white
                                        : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFE91E63)
                                      : city.enabled
                                          ? Colors.grey.shade300
                                          : Colors.grey.shade200,
                                  width: isSelected ? 2 : 1.5,
                                ),
                                boxShadow: city.enabled && !isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          city.emoji,
                                          style: TextStyle(
                                            fontSize: 32,
                                            color: city.enabled
                                                ? null
                                                : Colors.grey.shade400,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          city.name,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? const Color(0xFFE91E63)
                                                : city.enabled
                                                    ? Colors.black87
                                                    : Colors.grey.shade400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // "Coming soon" badge for disabled cities
                                  if (!city.enabled)
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Soon',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  // Checkmark for selected
                                  if (isSelected)
                                    const Positioned(
                                      top: 12,
                                      right: 12,
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Color(0xFFE91E63),
                                        size: 20,
                                      ),
                                    ),
                                ],
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
