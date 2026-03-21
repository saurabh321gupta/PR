import 'package:flutter/material.dart';
import 'photo_screen.dart';
import 'setup_progress_bar.dart';

// ── Silhouette painters for interest options ────────────────────

class _WomanSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final cx = size.width / 2;

    // Head
    canvas.drawCircle(Offset(cx, size.height * 0.24), size.width * 0.17, paint);

    // Shoulders + body (wider, softer)
    final bodyPath = Path()
      ..moveTo(cx - size.width * 0.32, size.height * 0.85)
      ..quadraticBezierTo(cx - size.width * 0.34, size.height * 0.52, cx - size.width * 0.12, size.height * 0.44)
      ..lineTo(cx + size.width * 0.12, size.height * 0.44)
      ..quadraticBezierTo(cx + size.width * 0.34, size.height * 0.52, cx + size.width * 0.32, size.height * 0.85)
      ..close();
    canvas.drawPath(bodyPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ManSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final cx = size.width / 2;

    // Head
    canvas.drawCircle(Offset(cx, size.height * 0.22), size.width * 0.16, paint);

    // Broader shoulders
    final bodyPath = Path()
      ..moveTo(cx - size.width * 0.38, size.height * 0.85)
      ..quadraticBezierTo(cx - size.width * 0.40, size.height * 0.50, cx - size.width * 0.14, size.height * 0.42)
      ..lineTo(cx + size.width * 0.14, size.height * 0.42)
      ..quadraticBezierTo(cx + size.width * 0.40, size.height * 0.50, cx + size.width * 0.38, size.height * 0.85)
      ..close();
    canvas.drawPath(bodyPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EveryoneSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    // Left person (slightly behind, shifted left)
    final lx = size.width * 0.35;
    canvas.drawCircle(Offset(lx, size.height * 0.24), size.width * 0.13, paint);
    final leftBody = Path()
      ..moveTo(lx - size.width * 0.24, size.height * 0.85)
      ..quadraticBezierTo(lx - size.width * 0.26, size.height * 0.52, lx - size.width * 0.09, size.height * 0.44)
      ..lineTo(lx + size.width * 0.09, size.height * 0.44)
      ..quadraticBezierTo(lx + size.width * 0.26, size.height * 0.52, lx + size.width * 0.24, size.height * 0.85)
      ..close();
    canvas.drawPath(leftBody, paint);

    // Right person (slightly in front, shifted right)
    final rx = size.width * 0.65;
    canvas.drawCircle(Offset(rx, size.height * 0.24), size.width * 0.13, paint);
    final rightBody = Path()
      ..moveTo(rx - size.width * 0.24, size.height * 0.85)
      ..quadraticBezierTo(rx - size.width * 0.26, size.height * 0.52, rx - size.width * 0.09, size.height * 0.44)
      ..lineTo(rx + size.width * 0.09, size.height * 0.44)
      ..quadraticBezierTo(rx + size.width * 0.26, size.height * 0.52, rx + size.width * 0.24, size.height * 0.85)
      ..close();
    canvas.drawPath(rightBody, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Interest option model ───────────────────────────────────────

class _InterestOption {
  final String label;
  final String subtitle;
  final List<Color> gradient;
  final CustomPainter painter;

  const _InterestOption({
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.painter,
  });
}

// ── Screen ──────────────────────────────────────────────────────

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

  static final List<_InterestOption> _options = [
    _InterestOption(
      label: 'Women',
      subtitle: 'Show me women',
      gradient: const [Color(0xFFEC407A), Color(0xFFF48FB1)],
      painter: _WomanSilhouettePainter(),
    ),
    _InterestOption(
      label: 'Men',
      subtitle: 'Show me men',
      gradient: const [Color(0xFF42A5F5), Color(0xFF90CAF9)],
      painter: _ManSilhouettePainter(),
    ),
    _InterestOption(
      label: 'Everyone',
      subtitle: 'Show me everyone',
      gradient: const [Color(0xFFAB47BC), Color(0xFFCE93D8)],
      painter: _EveryoneSilhouettePainter(),
    ),
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
                    const SizedBox(height: 32),

                    // Interest cards with gradient avatars
                    ...List.generate(_options.length, (index) {
                      final option = _options[index];
                      final isSelected = _selectedInterest == option.label;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedInterest = option.label),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected ? option.gradient[0].withValues(alpha: 0.06) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? option.gradient[0] : Colors.grey.shade300,
                                width: isSelected ? 2 : 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: option.gradient[0].withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                // Gradient avatar with silhouette
                                Container(
                                  width: 52, height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: isSelected
                                          ? option.gradient
                                          : [Colors.grey.shade300, Colors.grey.shade400],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isSelected ? option.gradient[0] : Colors.grey).withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: CustomPaint(painter: option.painter),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        option.label,
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected ? option.gradient[0] : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        option.subtitle,
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                ),
                                // Radio indicator
                                Container(
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? option.gradient[0] : Colors.grey.shade400,
                                      width: 2,
                                    ),
                                    color: isSelected ? option.gradient[0] : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                                      : null,
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
