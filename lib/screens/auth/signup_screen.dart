import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'otp_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isWorkEmail(String email) {
    final personalDomains = [
      'gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com',
      'icloud.com', 'protonmail.com', 'rediffmail.com',
    ];
    final domain = email.split('@').last.toLowerCase();
    return !personalDomains.contains(domain);
  }

  String? _validate(String email) {
    if (email.isEmpty) return 'Please enter your work email';
    if (!email.contains('@') || !email.contains('.')) {
      return 'Enter a valid email address';
    }
    // TODO: Re-enable work email check before launch
    // if (!_isWorkEmail(email)) {
    //   return 'Please use your work email, not a personal one';
    // }
    return null;
  }

  Future<void> _sendVerificationCode() async {
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

    // Check for existing account
    final exists = await _authService.emailExists(email);
    if (exists) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      _showAlreadyExistsDialog();
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

  void _showAlreadyExistsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text('Account exists', style: AppTextStyles.headlineSm),
        content: Text(
          'This email already has an account. Please sign in instead.',
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
            child: Text('Sign In',
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
                    Text(
                      'Let\'s start with\nyour work email.',
                      style: AppTextStyles.headlineLg.copyWith(height: 1.25),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      'We only use work emails to make sure everyone on Grred is real.',
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

                    // Privacy assurances
                    _buildAssurance(
                      Icons.lock_outline,
                      'Your email is never shared with anyone and won\'t be on your profile.',
                    ),
                    const SizedBox(height: 12),
                    _buildAssurance(
                      Icons.business_outlined,
                      'You can choose later whether to see people from the same organization or not.',
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
                  onPressed: _isLoading ? null : _sendVerificationCode,
                  isLoading: _isLoading,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssurance(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.outline),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.outline),
          ),
        ),
      ],
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
