import 'package:flutter/material.dart';
import 'interest_screen.dart';
import 'setup_progress_bar.dart';

class GenderScreen extends StatefulWidget {
  final String userId;
  final String workEmail;
  final String city;
  final String firstName;
  final int age;

  const GenderScreen({
    super.key,
    required this.userId,
    required this.workEmail,
    required this.city,
    required this.firstName,
    required this.age,
  });

  @override
  State<GenderScreen> createState() => _GenderScreenState();
}

class _GenderScreenState extends State<GenderScreen> {
  String? _selectedGender;
  bool _showOnProfile = true;

  static const List<String> _genders = ['Woman', 'Man', 'Nonbinary', 'Prefer not to say'];

  void _proceed() {
    if (_selectedGender == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InterestScreen(
          userId: widget.userId,
          workEmail: widget.workEmail,
          city: widget.city,
          firstName: widget.firstName,
          age: widget.age,
          gender: _selectedGender!,
          showGender: _showOnProfile,
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
            const SetupProgressBar(currentStep: 2, totalSteps: 5),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),
                    Text(
                      '${widget.firstName} is a\ngreat name',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.black87, height: 1.25),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'We love that you\'re here. Pick the gender that best describes you.',
                      style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.5),
                    ),
                    const SizedBox(height: 24),

                    Text('Which gender best describes you?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                    const SizedBox(height: 14),

                    ...List.generate(_genders.length, (index) {
                      final gender = _genders[index];
                      final isSelected = _selectedGender == gender;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedGender = gender),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                                Expanded(child: Text(gender, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: isSelected ? const Color(0xFFE91E63) : Colors.black87))),
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

                    const SizedBox(height: 8),

                    // Show on profile toggle
                    Row(
                      children: [
                        Expanded(
                          child: Text('Show on profile', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                        ),
                        Switch(
                          value: _showOnProfile,
                          onChanged: (val) => setState(() => _showOnProfile = val),
                          activeTrackColor: const Color(0xFFE91E63),
                        ),
                      ],
                    ),

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
                    onPressed: _selectedGender != null ? _proceed : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: const CircleBorder(), padding: EdgeInsets.zero, elevation: 2,
                    ),
                    child: Icon(Icons.arrow_forward, color: _selectedGender != null ? Colors.white : Colors.grey.shade500, size: 26),
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
