import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import 'city_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final bool isSignIn;
  final String? devOtp;

  const OtpScreen({
    super.key,
    required this.email,
    this.isSignIn = false,
    this.devOtp,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _authService = AuthService();
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  String _errorMessage = '';

  // Countdown timer (Bumble shows "This code should arrive within Xs")
  int _secondsRemaining = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _startCountdown() {
    _secondsRemaining = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _enteredOtp => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_enteredOtp.length < 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final isValid = await _authService.verifyOtp(widget.email, _enteredOtp);

    if (!isValid) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid or expired code. Try again.';
      });
      return;
    }

    // OTP valid — sign in or create account
    try {
      final user = widget.isSignIn
          ? await _authService.signIn(widget.email)
          : await _authService.createAccount(widget.email);

      if (!mounted) return;

      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = widget.isSignIn
              ? 'Sign in failed. Try again.'
              : 'Account creation failed. Try again.';
        });
        return;
      }

      setState(() => _isLoading = false);

      if (widget.isSignIn) {
        final hasProfile = await _authService.hasProfile(user.uid);
        if (!mounted) return;
        if (hasProfile) {
          // Pop all auth screens (OTP + SignIn) back to _AuthGate root.
          // _AuthGate's StreamBuilder already detected the sign-in and
          // will show HomeScreen.
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          // Signed in but no profile — incomplete onboarding.
          // Replace this screen with CityScreen to start onboarding.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CityScreen(
                userId: user.uid,
                workEmail: widget.email,
              ),
            ),
          );
        }
      } else {
        // New account created — start onboarding.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CityScreen(
              userId: user.uid,
              workEmail: widget.email,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  void _onDigitEntered(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    // Auto-verify when all 6 digits entered
    if (_enteredOtp.length == 6) {
      _verify();
    }
  }

  void _handleKeyEvent(int index, KeyEvent event) {
    // Handle backspace on empty field to go back
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
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

                    // Heading (Bumble style)
                    const Text(
                      'Verify your email',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subtitle with email
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(
                              text: 'Enter the code we\'ve sent to\n'),
                          TextSpan(
                            text: widget.email,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // "Change email" link (like Bumble's "Change number")
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Change email',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE91E63),
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFFE91E63),
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // "Code" label
                    Text(
                      'Code',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 6-digit OTP input (Bumble style — rounded boxes)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 48,
                          height: 56,
                          child: KeyboardListener(
                            focusNode: FocusNode(),
                            onKeyEvent: (event) =>
                                _handleKeyEvent(index, event),
                            child: TextFormField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFE91E63), width: 2),
                                ),
                              ),
                              onChanged: (val) =>
                                  _onDigitEntered(index, val),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 16),

                    // Error message
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13),
                        ),
                      ),

                    // Loading indicator
                    if (_isLoading)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Loading...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Countdown timer (Bumble style)
                    if (_secondsRemaining > 0)
                      Text(
                        'This code should arrive within ${_secondsRemaining}s',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    if (_secondsRemaining == 0)
                      GestureDetector(
                        onTap: () {
                          // Go back to resend
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Didn\'t receive it? Go back and try again',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFE91E63),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Dev OTP banner
                    if (widget.devOtp != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          border: Border.all(color: Colors.amber.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.bug_report,
                                color: Colors.amber.shade700, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              'Dev OTP: ${widget.devOtp}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
