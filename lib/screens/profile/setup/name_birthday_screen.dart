import 'package:flutter/material.dart';
import 'gender_screen.dart';
import 'setup_progress_bar.dart';

class NameBirthdayScreen extends StatefulWidget {
  final String userId;
  final String workEmail;
  final String city;

  const NameBirthdayScreen({
    super.key,
    required this.userId,
    required this.workEmail,
    required this.city,
  });

  @override
  State<NameBirthdayScreen> createState() => _NameBirthdayScreenState();
}

class _NameBirthdayScreenState extends State<NameBirthdayScreen> {
  final _nameController = TextEditingController();
  DateTime? _birthday;
  String? _nameError;
  String? _birthdayError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int? get _age {
    if (_birthday == null) return null;
    final now = DateTime.now();
    int age = now.year - _birthday!.year;
    if (now.month < _birthday!.month ||
        (now.month == _birthday!.month && now.day < _birthday!.day)) {
      age--;
    }
    return age;
  }

  String get _formattedBirthday {
    if (_birthday == null) return '';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[_birthday!.month]} ${_birthday!.day}, ${_birthday!.year}';
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 22, 1, 1),
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 18),
      helpText: 'When were you born?',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE91E63),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthday = picked;
        _birthdayError = null;
      });

      if (!mounted) return;
      _showAgeConfirmation();
    }
  }

  void _showAgeConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "You're $_age",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              "This is locked in forever — no Benjamin Button allowed.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _birthday = null);
            },
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE91E63))),
          ),
        ],
      ),
    );
  }

  void _proceed() {
    final name = _nameController.text.trim();
    bool hasError = false;

    if (name.isEmpty) {
      setState(() => _nameError = 'Please enter your first name');
      hasError = true;
    }
    if (_birthday == null) {
      setState(() => _birthdayError = 'Please select your birthday');
      hasError = true;
    }
    if (hasError) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GenderScreen(
          userId: widget.userId,
          workEmail: widget.workEmail,
          city: widget.city,
          firstName: name,
          age: _age!,
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
            const SetupProgressBar(currentStep: 1, totalSteps: 6),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),
                    const Text(
                      'First things first —\nwho are we talking to?',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.black87, height: 1.25),
                    ),
                    const SizedBox(height: 32),

                    Text('Your first name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade500)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(fontSize: 17),
                      decoration: InputDecoration(
                        hintText: 'First name',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5)),
                        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE91E63), width: 2)),
                        errorText: _nameError,
                      ),
                      onChanged: (_) {
                        if (_nameError != null) setState(() => _nameError = null);
                      },
                    ),

                    const SizedBox(height: 32),

                    Text('Your birthday', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade500)),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickBirthday,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: _birthdayError != null ? Colors.red : Colors.grey.shade300, width: 1.5)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _birthday != null ? _formattedBirthday : 'Tap to select',
                                style: TextStyle(fontSize: 17, color: _birthday != null ? Colors.black87 : Colors.grey.shade400),
                              ),
                            ),
                            if (_age != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFFFCE4EC), borderRadius: BorderRadius.circular(12)),
                                child: Text('Age $_age', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFE91E63))),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (_birthdayError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(_birthdayError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                    const SizedBox(height: 16),
                    Text("We won't sing, but we do like knowing when to 🎂", style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
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
                    onPressed: _proceed,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63), shape: const CircleBorder(), padding: EdgeInsets.zero, elevation: 2),
                    child: const Icon(Icons.arrow_forward, color: Colors.white, size: 26),
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
