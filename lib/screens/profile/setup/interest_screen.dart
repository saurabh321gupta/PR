import 'package:flutter/material.dart';
import 'photo_screen.dart';
import 'setup_progress_bar.dart';

class InterestScreen extends StatefulWidget {
  final String userId;
  final String workEmail;
  final String city;
  final String firstName;
  final int age;
  final String gender;
  final bool showGender;

  const InterestScreen({
    super.key,
    required this.userId,
    required this.workEmail,
    required this.city,
    required this.firstName,
    required this.age,
    required this.gender,
    required this.showGender,
  });

  @override
  State<InterestScreen> createState() => _InterestScreenState();
}

class _InterestScreenState extends State<InterestScreen> {
  String? _selectedInterest;

  static const List<Map<String, String>> _options = [
    {'label': 'Men', 'emoji': '\u{1F468}'},
    {'label': 'Women', 'emoji': '\u{1F469}'},
    {'label': 'Everyone', 'emoji': '\u{1F49B}'},
  ];

  void _proceed() {
    if (_selectedInterest == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoScreen(
          userId: widget.userId,
          workEmail: widget.workEmail,
          city: widget.city,
          firstName: widget.firstName,
          age: widget.age,
          gender: widget.gender,
          showGender: widget.showGender,
          interestedIn: _selectedInterest!,
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
            const SetupProgressBar(currentStep: 3, totalSteps: 6),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),
                    const Text(
                      'So, who catches\nyour eye?',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.black87, height: 1.25),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No pressure — you can always update this later.',
                      style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.5),
                    ),
                    const SizedBox(height: 28),

                    ...List.generate(_options.length, (index) {
                      final option = _options[index];
                      final isSelected = _selectedInterest == option['label'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedInterest = option['label']),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFCE4EC) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFE91E63) : Colors.grey.shade300,
                                width: isSelected ? 2 : 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(option['emoji']!, style: const TextStyle(fontSize: 24)),
                                const SizedBox(width: 14),
                                Expanded(child: Text(option['label']!, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: isSelected ? const Color(0xFFE91E63) : Colors.black87))),
                                Container(
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: isSelected ? const Color(0xFFE91E63) : Colors.grey.shade400, width: 2),
                                    color: isSelected ? const Color(0xFFE91E63) : Colors.transparent,
                                  ),
                                  child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    const Spacer(),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(right: 28, bottom: 24),
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 56, height: 56,
                  child: ElevatedButton(
                    onPressed: _selectedInterest != null ? _proceed : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: const CircleBorder(), padding: EdgeInsets.zero, elevation: 2,
                    ),
                    child: Icon(Icons.arrow_forward, color: _selectedInterest != null ? Colors.white : Colors.grey.shade500, size: 26),
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
