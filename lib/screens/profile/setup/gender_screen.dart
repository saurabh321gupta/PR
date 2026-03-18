import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'interest_screen.dart';
import 'setup_progress_bar.dart';

// ── Custom painters for gender symbols ──────────────────────────

class _FemalePainter extends CustomPainter {
  final Color color;
  _FemalePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.16
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final radius = size.width * 0.28;
    final circleCenter = Offset(cx, size.height * 0.36);

    // Circle
    canvas.drawCircle(circleCenter, radius, paint);

    // Vertical line down from circle
    final lineStart = Offset(cx, circleCenter.dy + radius);
    final lineEnd = Offset(cx, size.height * 0.88);
    canvas.drawLine(lineStart, lineEnd, paint);

    // Horizontal cross
    final crossY = (lineStart.dy + lineEnd.dy) / 2;
    final crossHalf = size.width * 0.16;
    canvas.drawLine(Offset(cx - crossHalf, crossY), Offset(cx + crossHalf, crossY), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MalePainter extends CustomPainter {
  final Color color;
  _MalePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.16
      ..strokeCap = StrokeCap.round;

    final radius = size.width * 0.28;
    final circleCenter = Offset(size.width * 0.4, size.height * 0.58);

    // Circle
    canvas.drawCircle(circleCenter, radius, paint);

    // Arrow line going to top-right from circle edge
    final angle = -math.pi / 4; // 45 degrees up-right
    final arrowStart = Offset(
      circleCenter.dx + radius * math.cos(angle),
      circleCenter.dy + radius * math.sin(angle),
    );
    final arrowEnd = Offset(size.width * 0.82, size.height * 0.16);
    canvas.drawLine(arrowStart, arrowEnd, paint);

    // Arrowhead lines
    final arrowLen = size.width * 0.18;
    canvas.drawLine(arrowEnd, Offset(arrowEnd.dx - arrowLen, arrowEnd.dy), paint);
    canvas.drawLine(arrowEnd, Offset(arrowEnd.dx, arrowEnd.dy + arrowLen), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NonbinaryPainter extends CustomPainter {
  final Color color;
  _NonbinaryPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.14
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final radius = size.width * 0.24;
    final circleCenter = Offset(cx, size.height * 0.5);

    // Circle
    canvas.drawCircle(circleCenter, radius, paint);

    // Arrow up (male-ish)
    final topLineStart = Offset(cx, circleCenter.dy - radius);
    final topLineEnd = Offset(cx, size.height * 0.08);
    canvas.drawLine(topLineStart, topLineEnd, paint);

    // Cross down (female-ish)
    final bottomLineStart = Offset(cx, circleCenter.dy + radius);
    final bottomLineEnd = Offset(cx, size.height * 0.92);
    canvas.drawLine(bottomLineStart, bottomLineEnd, paint);
    final crossY = (bottomLineStart.dy + bottomLineEnd.dy) / 2;
    final crossH = size.width * 0.14;
    canvas.drawLine(Offset(cx - crossH, crossY), Offset(cx + crossH, crossY), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Gender data model ───────────────────────────────────────────

class _GenderOption {
  final String label;
  final Color color;
  final CustomPainter Function(Color color) painterBuilder;

  const _GenderOption({
    required this.label,
    required this.color,
    required this.painterBuilder,
  });
}

// ── Screen ──────────────────────────────────────────────────────

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

  static final List<_GenderOption> _genders = [
    _GenderOption(label: 'Woman', color: const Color(0xFFE91E63), painterBuilder: (c) => _FemalePainter(color: c)),
    _GenderOption(label: 'Man', color: const Color(0xFF42A5F5), painterBuilder: (c) => _MalePainter(color: c)),
    _GenderOption(label: 'Nonbinary', color: const Color(0xFF9C27B0), painterBuilder: (c) => _NonbinaryPainter(color: c)),
  ];

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
            const SetupProgressBar(currentStep: 2, totalSteps: 6),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),
                    Text(
                      'Nice to meet you,\n${widget.firstName} 👋',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.black87, height: 1.25),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Help us personalise your experience. This stays private unless you say otherwise.',
                      style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.5),
                    ),
                    const SizedBox(height: 24),

                    Text('I identify as...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                    const SizedBox(height: 14),

                    // Gender cards with painted symbols
                    ...List.generate(_genders.length, (index) {
                      final gender = _genders[index];
                      final isSelected = _selectedGender == gender.label;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedGender = gender.label),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                            decoration: BoxDecoration(
                              color: isSelected ? gender.color.withValues(alpha: 0.08) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? gender.color : Colors.grey.shade300,
                                width: isSelected ? 2 : 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Painted gender symbol
                                SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CustomPaint(
                                    painter: gender.painterBuilder(
                                      isSelected ? gender.color : Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    gender.label,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected ? gender.color : Colors.black87,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: isSelected ? gender.color : Colors.grey.shade400, width: 2),
                                    color: isSelected ? gender.color : Colors.transparent,
                                  ),
                                  child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    // "Prefer not to say" as a minimal text option
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedGender = 'Prefer not to say'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          decoration: BoxDecoration(
                            color: _selectedGender == 'Prefer not to say' ? Colors.grey.shade100 : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _selectedGender == 'Prefer not to say' ? Colors.grey.shade600 : Colors.grey.shade300,
                              width: _selectedGender == 'Prefer not to say' ? 2 : 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.remove_circle_outline, size: 28, color: _selectedGender == 'Prefer not to say' ? Colors.grey.shade700 : Colors.grey.shade500),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  'Prefer not to say',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: _selectedGender == 'Prefer not to say' ? Colors.grey.shade800 : Colors.black87,
                                  ),
                                ),
                              ),
                              Container(
                                width: 24, height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _selectedGender == 'Prefer not to say' ? Colors.grey.shade600 : Colors.grey.shade400, width: 2),
                                  color: _selectedGender == 'Prefer not to say' ? Colors.grey.shade600 : Colors.transparent,
                                ),
                                child: _selectedGender == 'Prefer not to say' ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

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
