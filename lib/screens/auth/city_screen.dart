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
  final String country;
  final String imageUrl;
  final bool enabled;

  const _CityItem({
    required this.name,
    required this.country,
    required this.imageUrl,
    this.enabled = true,
  });
}

class _CityScreenState extends State<CityScreen> {
  String? _selectedCity;

  static const List<_CityItem> _cities = [
    _CityItem(
      name: 'Bangalore',
      country: 'India',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuB_9U3u-XhB-Yn7v6oM9zKx9G6u6n7z8v9o-G-Yn7v6oM9zKx9G6u6n7z8v9o-G-Yn7v6oM9zKx9G6u6n7z8v9o-G-Yn7v6oM9zKx9G6u6n7z8v9o-G-Yn7v6oM9zKx9G6u6n7z8v9o-G-Yn7v6oM9zKx9G6u6n7z8v9o-G',
    ),
    _CityItem(
      name: 'Pune',
      country: 'India',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAtC5I9pD_9U3u-XhB-Yn7v6oM9zKx9G6u6n7z8v9o-G-Yn7v6oM9zKx9G6u6n7z8v9o-G-Yn7v6oM9zKx9G6u6n7z8v9o-G-Yn7v6oM9zKx9G6u6n7z8v9o-G-Yn7v6oM9zKx9G6u6n7z8v9o-G-Yn7v6oM9zKx9G6u6n7z8v9o-G',
    ),
    _CityItem(
      name: 'Hyderabad',
      country: 'India',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBfJN7qFhT3dStZ2HjLOynjG_1aQUpMHyTXAJxXz0DApTbR7USi8ayhEkwN45GusT_4oOWp2iY-rWrNgzFj8iEf-JeM8yp_bIHJbqQrQ1gC7WhK-7CFBEqoePH40Wk-YZI0HQarjaUAzStJF_zECn4Jc_CNZnWOk26dZNO_HvgR6XwV0VMHgoLVRNJNptrMOJ8v-e-8fecd4O9nEkgVpSYV_OUyYtQY-UL8ZEguP3aN1m9nWSRmGzyhHtLyl2PuUMPDycyQhiZvGYPi',
    ),
    _CityItem(
      name: 'Chennai',
      country: 'India',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuA7Yn7v6oM9zKx9G6u6n7z8v9o-G-Yn7v6oM9zKx9G6u6n7z8v9o-G-Yn7v6oM9zKx9G6u6n7z8v9o-G-Yn7v6oM9zKx9G6u6n7z8v9o-G-Yn7v6oM9zKx9G6u6n7z8v9o-G-Yn7v6oM9zKx9G6u6n7z8v9o-G',
    ),
    _CityItem(
      name: 'Delhi-NCR',
      country: 'India',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuB7iqHoYwYKhlaywsS5b_xSkBXGKbA8Vb1peKL1bYwsOJEuEVgJ6wUTyLrbARccEsqpuP54kNsgCSG2TvR3m3bVJkxscfUsyHNnzeLDkstdsYdG4fMM1OCUs0yNN5dR5Y1K1aFtALABv5n5u6xzoSk3eGEFPMZq4ksqQoduZUe9L24gw9CwPBL6lA2GxyBcUgkfbgAOPIa5xRKf_KU3DcIvYLTilNOnvDEi2_IKqeZsCL6x-81z7I6XoiKPxzBezbbCXYPdMvMUgsYi',
    ),
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
            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 24),
                    color: Colors.black87,
                  ),
                  const Text(
                    'Explore Places',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.my_location, size: 24),
                    color: Colors.black87,
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const SizedBox(height: 32),

                    // City tiles grid
                    Expanded(
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.75, // 3:4 ratio
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
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFE91E63)
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // Background Image
                                    Image.network(
                                      city.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey.shade300,
                                          child: const Icon(Icons.image,
                                              color: Colors.white, size: 40),
                                        );
                                      },
                                    ),

                                    // Gradient Overlay
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.2),
                                            Colors.black.withOpacity(0.8),
                                          ],
                                          stops: const [0.5, 0.7, 1.0],
                                        ),
                                      ),
                                    ),

                                    // Text Labels
                                    Positioned(
                                      bottom: 12,
                                      left: 12,
                                      right: 12,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            city.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            city.country.toUpperCase(),
                                            style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Checkmark for selected
                                    if (isSelected)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
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
