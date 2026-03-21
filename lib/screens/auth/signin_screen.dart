import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'otp_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validate(String email) {
    if (email.isEmpty) return 'Please enter your email';
    if (!email.contains('@') || !email.contains('.')) {
      return 'Enter a valid email address';
    }
    return null;
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    final error = _validate(email);
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    // Check account exists
    final exists = await _authService.emailExists(email);
    if (!exists) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      _showNoAccountDialog();
      return;
    }

    try {
      final otpResult = await _authService.sendOtp(email);
      setState(() => _isLoading = false);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            email: email,
            isSignIn: true,
            devOtp: otpResult.devOtp,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = 'Failed to send verification code. Try again.';
      });
    }
  }

  void _showNoAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text('No account found', style: AppTextStyles.headlineSm),
        content: Text(
          'No account found for this email. Please sign up first.',
          style: AppTextStyles.bodyLg,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: AppTextStyles.labelLg
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text('Sign Up',
                style: AppTextStyles.labelLg
                    .copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
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
                    Text('Welcome back!', style: AppTextStyles.headlineLg),
                    const SizedBox(height: 12),

                    Text(
                      'Enter your work email to sign in.',
                      style: AppTextStyles.bodyLg,
                    ),

                    const SizedBox(height: 36),

                    // Email label
                    Text('WORK EMAIL', style: AppTextStyles.sectionHeader),
                    const SizedBox(height: 10),

                    // Email input
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        color: AppColors.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'you@yourcompany.com',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 17,
                          color: AppColors.outline,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: AppColors.outlineVariant, width: 1.5),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: AppColors.primary, width: 2),
                        ),
                        errorBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: AppColors.error, width: 1.5),
                        ),
                        focusedErrorBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: AppColors.error, width: 2),
                        ),
                        errorText: _errorText,
                        errorStyle: AppTextStyles.bodySm
                            .copyWith(color: AppColors.error),
                      ),
                      onChanged: (_) {
                        if (_errorText != null) {
                          setState(() => _errorText = null);
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    // Privacy note
                    Row(
                      children: [
                        Icon(Icons.lock_outline,
                            size: 16, color: AppColors.outline),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'We\'ll send a code to your email to verify it\'s you.',
                            style: AppTextStyles.bodySm
                                .copyWith(color: AppColors.outline),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),
                  ],
                ),
              ),
            ),

            // Bottom CTA — gradient circular button
            Padding(
              padding: const EdgeInsets.only(right: 28, bottom: 24),
              child: Align(
                alignment: Alignment.centerRight,
                child: _buildCtaButton(
                  onPressed: _isLoading ? null : _sendCode,
                  isLoading: _isLoading,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCtaButton({
    required VoidCallback? onPressed,
    required bool isLoading,
  }) {
    final enabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: enabled ? AppColors.editorialGradient : null,
          color: enabled ? null : AppColors.outlineVariant,
          shape: BoxShape.circle,
          boxShadow: enabled ? AppShadows.fab : null,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 26),
        ),
      ),
    );
  }
}
