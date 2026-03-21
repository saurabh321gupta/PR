import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
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
  bool _isResending = false;
  String _errorMessage = '';
  String? _devOtp;

  int _secondsRemaining = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _devOtp = widget.devOtp;
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isResending = true;
      _errorMessage = '';
    });

    try {
      final result = await _authService.sendOtp(widget.email);
      if (!mounted) return;
      setState(() {
        _devOtp = result.devOtp;
        _isResending = false;
      });
      _startCountdown();
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _errorMessage = 'Failed to resend code. Try again.';
      });
    }
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
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
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
      final msg = e.toString();
      String errorText;
      if (msg.contains('timed out') ||
          msg.contains('timeout') ||
          msg.contains('DEADLINE_EXCEEDED')) {
        errorText = 'Connection timed out. Check your internet and try again.';
      } else if (msg.contains('already-exists')) {
        errorText =
            'An account with this email already exists. Try signing in.';
      } else if (msg.contains('not-found') || msg.contains('no_account')) {
        errorText = 'No account found for this email. Try signing up first.';
      } else if (msg.contains('unavailable') || msg.contains('UNAVAILABLE')) {
        errorText = 'Service temporarily unavailable. Please try again.';
      } else {
        errorText = 'Something went wrong. Please try again.';
      }
      setState(() {
        _isLoading = false;
        _errorMessage = errorText;
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
    if (_enteredOtp.length == 6) {
      _verify();
    }
  }

  void _handleKeyEvent(int index, KeyEvent event) {
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
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 24),
                color: AppColors.onSurface,
                splashRadius: 22,
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
                    Text('Verify your email',
                        style: AppTextStyles.headlineLg),
                    const SizedBox(height: 12),

                    // Subtitle with email
                    RichText(
                      text: TextSpan(
                        style: AppTextStyles.bodyLg,
                        children: [
                          const TextSpan(
                              text: 'Enter the code we\'ve sent to\n'),
                          TextSpan(
                            text: widget.email,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // "Change email" link
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Change email',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // "Code" label
                    Text('CODE', style: AppTextStyles.sectionHeader),
                    const SizedBox(height: 12),

                    // 6-digit OTP input
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
                              style: GoogleFonts.manrope(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.onSurface,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: AppColors.surfaceContainerLow,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                  borderSide: BorderSide(
                                      color: AppColors.outlineVariant),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                  borderSide: BorderSide(
                                      color: AppColors.outlineVariant),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                  borderSide: BorderSide(
                                      color: AppColors.primary, width: 2),
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
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.error),
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
                                color: AppColors.outline,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text('Verifying...',
                                style: AppTextStyles.bodyMd
                                    .copyWith(fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Countdown timer
                    if (_secondsRemaining > 0)
                      Text(
                        'This code should arrive within ${_secondsRemaining}s',
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.outline),
                      ),
                    if (_secondsRemaining == 0)
                      GestureDetector(
                        onTap: _isResending ? null : _resendOtp,
                        child: _isResending
                            ? Row(
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.outline,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Sending new code...',
                                    style: AppTextStyles.bodySm
                                        .copyWith(color: AppColors.outline),
                                  ),
                                ],
                              )
                            : Text(
                                'Didn\'t receive it? Resend code',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),

                    const SizedBox(height: 24),

                    // Dev OTP banner
                    if (_devOtp != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          border: Border.all(
                              color: AppColors.outlineVariant, width: 0.5),
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.bug_report_outlined,
                                color: AppColors.primary, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              'Dev OTP: $_devOtp',
                              style: GoogleFonts.manrope(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
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
