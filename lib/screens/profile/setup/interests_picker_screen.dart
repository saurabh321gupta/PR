import 'dart:io';
import 'package:flutter/material.dart';
import 'bio_screen.dart';
import 'setup_progress_bar.dart';

/// All available interests with emojis, grouped by category.
const List<Map<String, String>> _allInterests = [
  // Food & Drink
  {'label': 'Foodie', 'emoji': '🍕'},
  {'label': 'Coffee', 'emoji': '☕'},
  {'label': 'Wine', 'emoji': '🍷'},
  {'label': 'Cooking', 'emoji': '👨‍🍳'},
  {'label': 'Baking', 'emoji': '🧁'},
  {'label': 'Vegetarian', 'emoji': '🥗'},
  {'label': 'Brunch', 'emoji': '🥞'},
  {'label': 'Craft beer', 'emoji': '🍺'},

  // Fitness & Outdoors
  {'label': 'Gym', 'emoji': '🏋️'},
  {'label': 'Running', 'emoji': '🏃'},
  {'label': 'Yoga', 'emoji': '🧘'},
  {'label': 'Hiking', 'emoji': '🥾'},
  {'label': 'Cycling', 'emoji': '🚴'},
  {'label': 'Swimming', 'emoji': '🏊'},
  {'label': 'Camping', 'emoji': '⛺'},
  {'label': 'Cricket', 'emoji': '🏏'},

  // Music & Arts
  {'label': 'Live music', 'emoji': '🎵'},
  {'label': 'Concerts', 'emoji': '🎤'},
  {'label': 'Dancing', 'emoji': '💃'},
  {'label': 'Art', 'emoji': '🎨'},
  {'label': 'Photography', 'emoji': '📸'},
  {'label': 'Writing', 'emoji': '✍️'},
  {'label': 'Singing', 'emoji': '🎙️'},
  {'label': 'Bollywood', 'emoji': '🎬'},

  // Entertainment
  {'label': 'Netflix', 'emoji': '📺'},
  {'label': 'Anime', 'emoji': '🐉'},
  {'label': 'Gaming', 'emoji': '🎮'},
  {'label': 'Reading', 'emoji': '📚'},
  {'label': 'Podcasts', 'emoji': '🎧'},
  {'label': 'Standup comedy', 'emoji': '😂'},
  {'label': 'Horror', 'emoji': '👻'},
  {'label': 'Memes', 'emoji': '🤣'},

  // Lifestyle
  {'label': 'Travel', 'emoji': '✈️'},
  {'label': 'Dogs', 'emoji': '🐕'},
  {'label': 'Cats', 'emoji': '🐈'},
  {'label': 'Gardening', 'emoji': '🌱'},
  {'label': 'Astrology', 'emoji': '♈'},
  {'label': 'Spirituality', 'emoji': '🧿'},
  {'label': 'Volunteering', 'emoji': '🤝'},
  {'label': 'Road trips', 'emoji': '🚗'},

  // Tech & Career
  {'label': 'Startups', 'emoji': '🚀'},
  {'label': 'Investing', 'emoji': '📈'},
  {'label': 'Tech', 'emoji': '💻'},
  {'label': 'Design', 'emoji': '🎯'},
  {'label': 'Side projects', 'emoji': '⚡'},
  {'label': 'AI', 'emoji': '🤖'},

  // Social
  {'label': 'Board games', 'emoji': '🎲'},
  {'label': 'Parties', 'emoji': '🎉'},
  {'label': 'Karaoke', 'emoji': '🎤'},
  {'label': 'Deep talks', 'emoji': '💭'},
  {'label': 'Sarcasm', 'emoji': '😏'},
  {'label': 'Night owl', 'emoji': '🦉'},
  {'label': 'Early bird', 'emoji': '🌅'},
];

class InterestsPickerScreen extends StatefulWidget {
  final String userId;
  final String workEmail;
  final String city;
  final String firstName;
  final int age;
  final String gender;
  final bool showGender;
  final String interestedIn;
  final List<File> photos;

  const InterestsPickerScreen({
    super.key,
    required this.userId,
    required this.workEmail,
    required this.city,
    required this.firstName,
    required this.age,
    required this.gender,
    required this.showGender,
    required this.interestedIn,
    required this.photos,
  });

  @override
  State<InterestsPickerScreen> createState() => _InterestsPickerScreenState();
}

class _InterestsPickerScreenState extends State<InterestsPickerScreen> {
  static const int _minInterests = 3;
  static const int _maxInterests = 5;

  final Set<String> _selected = {};
  final _searchController = TextEditingController();
  String _searchQuery = '';

  bool get _canProceed => _selected.length >= _minInterests;

  List<Map<String, String>> get _filtered {
    if (_searchQuery.isEmpty) return _allInterests;
    final q = _searchQuery.toLowerCase();
    return _allInterests.where((i) => i['label']!.toLowerCase().contains(q)).toList();
  }

  void _toggle(String label) {
    setState(() {
      if (_selected.contains(label)) {
        _selected.remove(label);
      } else if (_selected.length < _maxInterests) {
        _selected.add(label);
      }
    });
  }

  void _proceed() {
    if (!_canProceed) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BioScreen(
          userId: widget.userId,
          workEmail: widget.workEmail,
          city: widget.city,
          firstName: widget.firstName,
          age: widget.age,
          gender: widget.gender,
          showGender: widget.showGender,
          interestedIn: widget.interestedIn,
          photos: widget.photos,
          interests: _selected.toList(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SetupProgressBar(currentStep: 5, totalSteps: 6),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),
                    const Text(
                      'Pick what makes\nyou, you ✌️',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.black87, height: 1.25),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Choose at least $_minInterests things you\'re into — it helps us find your kind of people.',
                      style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.5),
                    ),
                    const SizedBox(height: 20),

                    // Search bar
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Search interests...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 22),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE91E63), width: 1.5),
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    ),
                    const SizedBox(height: 20),

                    // Chips
                    Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 10,
                          children: _filtered.map((interest) {
                            final label = interest['label']!;
                            final emoji = interest['emoji']!;
                            final isSelected = _selected.contains(label);
                            final isMaxed = _selected.length >= _maxInterests && !isSelected;

                            return GestureDetector(
                              onTap: isMaxed ? null : () => _toggle(label),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFE91E63).withValues(alpha: 0.1)
                                      : isMaxed
                                          ? Colors.grey.shade100
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFE91E63)
                                        : isMaxed
                                            ? Colors.grey.shade200
                                            : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1.2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(emoji, style: const TextStyle(fontSize: 16)),
                                    const SizedBox(width: 6),
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                        color: isSelected
                                            ? const Color(0xFFE91E63)
                                            : isMaxed
                                                ? Colors.grey.shade400
                                                : Colors.black87,
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.check, size: 16, color: Color(0xFFE91E63)),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Bottom bar: counter + proceed
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28).copyWith(bottom: 24),
              child: Row(
                children: [
                  // Counter
                  Text(
                    '${_selected.length}/$_maxInterests selected',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _canProceed ? const Color(0xFFE91E63) : Colors.grey.shade500,
                    ),
                  ),
                  if (_selected.length < _minInterests) ...[
                    const SizedBox(width: 6),
                    Text(
                      '(${_minInterests - _selected.length} more needed)',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                    ),
                  ],
                  const Spacer(),
                  // Proceed button
                  SizedBox(
                    width: 56, height: 56,
                    child: ElevatedButton(
                      onPressed: _canProceed ? _proceed : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE91E63),
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                        elevation: 2,
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        color: _canProceed ? Colors.white : Colors.grey.shade500,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
