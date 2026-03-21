import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../landing_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storageService = StorageService();
  final _picker = ImagePicker();

  UserModel? _userModel;
  bool _isLoading = true;
  bool _isSaving = false;

  // Edit mode controllers
  final _bioController = TextEditingController();
  String _selectedInterest = 'Everyone';
  final List<String> _interests = ['Men', 'Women', 'Everyone'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------------

  Future<void> _loadProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && mounted) {
      setState(() {
        _userModel = UserModel.fromMap(uid, doc.data()!);
        _bioController.text = _userModel!.bio;
        _selectedInterest = _userModel!.interestedIn;
        _isLoading = false;
      });
    } else if (mounted) {
      // FIX: release spinner when profile document does not exist
      setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Photo change
  // ---------------------------------------------------------------------------

  Future<void> _changePhoto() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isSaving = true);

    try {
      final uid = _auth.currentUser!.uid;
      final url =
          await _storageService.uploadProfilePhoto(uid, File(picked.path));

      await _firestore.collection('users').doc(uid).update({
        'photos': [url],
      });

      setState(() {
        _userModel = UserModel(
          id: _userModel!.id,
          firstName: _userModel!.firstName,
          age: _userModel!.age,
          gender: _userModel!.gender,
          bio: _userModel!.bio,
          photos: [url],
          interests: _userModel!.interests,
          city: _userModel!.city,
          companyDomain: _userModel!.companyDomain,
          workVerified: _userModel!.workVerified,
          industryCategory: _userModel!.industryCategory,
          role: _userModel!.role,
          showIndustry: _userModel!.showIndustry,
          showRole: _userModel!.showRole,
          createdAt: _userModel!.createdAt,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo updated'),
            backgroundColor: AppColors.tertiary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Interest / preference save
  // ---------------------------------------------------------------------------

  Future<void> _saveInterest(String newInterest) async {
    if (newInterest == _userModel?.interestedIn) return;
    setState(() => _isSaving = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'interestedIn': newInterest});
    setState(() {
      _selectedInterest = newInterest;
      _isSaving = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preference updated'),
          backgroundColor: AppColors.tertiary,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Bio save
  // ---------------------------------------------------------------------------

  Future<void> _saveBio() async {
    final newBio = _bioController.text.trim();
    if (newBio.isEmpty || newBio == _userModel?.bio) return;

    setState(() => _isSaving = true);
    final uid = _auth.currentUser!.uid;

    await _firestore.collection('users').doc(uid).update({'bio': newBio});

    setState(() {
      _userModel = UserModel(
        id: _userModel!.id,
        firstName: _userModel!.firstName,
        age: _userModel!.age,
        gender: _userModel!.gender,
        bio: newBio,
        photos: _userModel!.photos,
        interests: _userModel!.interests,
        city: _userModel!.city,
        companyDomain: _userModel!.companyDomain,
        workVerified: _userModel!.workVerified,
        industryCategory: _userModel!.industryCategory,
        role: _userModel!.role,
        showIndustry: _userModel!.showIndustry,
        showRole: _userModel!.showRole,
        createdAt: _userModel!.createdAt,
      );
      _isSaving = false;
    });

    if (mounted) {
      Navigator.pop(context); // dismiss bottom sheet
      FocusScope.of(context).unfocus();
    }
  }

  // ---------------------------------------------------------------------------
  // Sign-out with confirmation
  // ---------------------------------------------------------------------------

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        backgroundColor: AppColors.surfaceContainerLowest,
        title: Text('Sign out?', style: AppTextStyles.headlineSm),
        content: Text(
          "You'll need to verify your work email to sign back in.",
          style: AppTextStyles.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: AppTextStyles.labelLg
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _auth.signOut();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (_) => false,
    );
  }

  // ---------------------------------------------------------------------------
  // Image source picker
  // ---------------------------------------------------------------------------

  Future<ImageSource?> _showImageSourceDialog() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('Change photo', style: AppTextStyles.headlineSm),
            const SizedBox(height: 8),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppColors.primary),
              title: Text('Choose from gallery', style: AppTextStyles.labelLg),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: Text('Take a photo', style: AppTextStyles.labelLg),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bio edit bottom sheet
  // ---------------------------------------------------------------------------

  void _showBioEditor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Edit your summary', style: AppTextStyles.headlineSm),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              maxLines: 5,
              maxLength: 200,
              style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'Write something about yourself...',
                hintStyle: AppTextStyles.bodyLg
                    .copyWith(color: AppColors.outlineVariant),
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
                counterStyle: AppTextStyles.bodySm,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveBio,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
                child: Text('Save',
                    style: AppTextStyles.labelLg
                        .copyWith(color: AppColors.onPrimary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _userModel == null
              ? Center(
                  child: Text('No profile found.', style: AppTextStyles.bodyLg))
              : Stack(
                  children: [
                    _buildBody(),
                    _buildGlassmorphicHeader(),
                  ],
                ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Glassmorphic fixed header
  // ---------------------------------------------------------------------------

  Widget _buildGlassmorphicHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: AppColors.surface.withOpacity(0.80),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                ),
                child: SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.menu, color: AppColors.primary),
                        onPressed: () {},
                      ),
                      const Spacer(),
                      Text('Grred', style: AppTextStyles.brand),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined,
                            color: AppColors.primary),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Subtle divider
          Container(
            height: 1,
            color: AppColors.outlineVariant.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Scrollable body
  // ---------------------------------------------------------------------------

  Widget _buildBody() {
    final topPadding = MediaQuery.of(context).padding.top + 56 + 1;

    return SingleChildScrollView(
      padding: EdgeInsets.only(top: topPadding + 16, bottom: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2. Profile Photo Header
          _buildPhotoHeader(),
          const SizedBox(height: 24),

          // 3. The Executive Summary (bio)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildExecutiveSummary(),
          ),
          const SizedBox(height: 16),

          // 4. Quick Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildQuickStats(),
          ),
          const SizedBox(height: 32),

          // 5. Account & Preferences
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildAccountPreferences(),
          ),
          const SizedBox(height: 40),

          // 6. Sign Out
          _buildSignOutButton(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Profile Photo Header (editorial, 4:5, gradient overlay)
  // ---------------------------------------------------------------------------

  Widget _buildPhotoHeader() {
    final user = _userModel!;
    final hasPhoto = user.photos.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          // Photo container
          AspectRatio(
            aspectRatio: 4 / 5,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.ambient,
                color: AppColors.surfaceContainerHigh,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image or placeholder
                  if (hasPhoto)
                    Image.network(
                      user.photos[0],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _photoPlaceholder(user),
                    )
                  else
                    _photoPlaceholder(user),

                  // Saving overlay
                  if (_isSaving)
                    Container(
                      color: AppColors.onSurface.withOpacity(0.35),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),

                  // Bottom gradient overlay
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 200,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(AppRadius.lg),
                          bottomRight: Radius.circular(AppRadius.lg),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppColors.onSurface.withOpacity(0.60),
                            AppColors.onSurface.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Name + role over gradient
                  Positioned(
                    left: 24,
                    bottom: 24,
                    right: 80,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${user.firstName}, ${user.age}',
                          style: GoogleFonts.manrope(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (user.role.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            user.role,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.90),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Edit FAB — bottom right, overlapping photo edge
          Positioned(
            right: 16,
            bottom: -28,
            child: GestureDetector(
              onTap: _changePhoto,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.editorialGradient,
                  boxShadow: AppShadows.fab,
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
        clipBehavior: Clip.none,
      ),
    );
  }

  Widget _photoPlaceholder(UserModel user) {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: Center(
        child: Text(
          user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
          style: GoogleFonts.manrope(
            fontSize: 80,
            fontWeight: FontWeight.w800,
            color: AppColors.primary.withOpacity(0.30),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. The Executive Summary card
  // ---------------------------------------------------------------------------

  Widget _buildExecutiveSummary() {
    final user = _userModel!;

    return GestureDetector(
      onTap: _showBioEditor,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.article_outlined,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Text(
                  'The Executive Summary',
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              user.bio.isNotEmpty
                  ? user.bio
                  : 'Tap to write something about yourself...',
              style: AppTextStyles.bodyLg.copyWith(
                color: user.bio.isNotEmpty
                    ? AppColors.onSurfaceVariant
                    : AppColors.outlineVariant,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Quick Stats card
  // ---------------------------------------------------------------------------

  Widget _buildQuickStats() {
    final user = _userModel!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          _statRow(
            icon: Icons.location_on_outlined,
            label: 'LOCATION',
            value: user.city.isNotEmpty ? user.city : 'Not set',
          ),
          const SizedBox(height: 16),
          _statRow(
            icon: Icons.person_outline,
            label: 'GENDER',
            value: user.gender,
          ),
          const SizedBox(height: 16),
          _statRow(
            icon: Icons.cake_outlined,
            label: 'AGE',
            value: '${user.age}',
          ),
          const SizedBox(height: 16),
          _statRow(
            icon: Icons.verified_outlined,
            label: 'VERIFIED VIA',
            value: user.companyDomain,
          ),
        ],
      ),
    );
  }

  Widget _statRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.labelSm.copyWith(
                letterSpacing: 1.5,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTextStyles.labelLg.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Account & Preferences
  // ---------------------------------------------------------------------------

  Widget _buildAccountPreferences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account & Preferences',
          style: GoogleFonts.manrope(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 20),

        // Discovery Settings
        _settingRow(
          icon: Icons.explore_outlined,
          title: 'Discovery Settings',
          subtitle: 'Show me: $_selectedInterest',
          onTap: _showDiscoverySheet,
        ),
        const SizedBox(height: 16),

        // Notifications
        _settingRow(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'Manage push notifications',
          onTap: () {},
        ),
        const SizedBox(height: 16),

        // Privacy & Security
        _settingRow(
          icon: Icons.shield_outlined,
          title: 'Privacy & Security',
          subtitle: 'Control your data and visibility',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _settingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.onSurface, size: 24),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.labelLg
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.bodySm),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.outlineVariant),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Discovery preference bottom sheet
  // ---------------------------------------------------------------------------

  void _showDiscoverySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Show me', style: AppTextStyles.headlineSm),
              const SizedBox(height: 16),
              ..._interests.map((interest) {
                final isSelected = interest == _selectedInterest;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: _isSaving
                        ? null
                        : () {
                            _saveInterest(interest);
                            Navigator.pop(context);
                          },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.surfaceContainerHigh
                            : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: isSelected
                            ? Border.all(color: AppColors.primary, width: 2)
                            : null,
                      ),
                      child: Text(
                        interest,
                        style: AppTextStyles.labelLg.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.onSurface,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Sign Out button
  // ---------------------------------------------------------------------------

  Widget _buildSignOutButton() {
    return Center(
      child: GestureDetector(
        onTap: _signOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: AppColors.outlineVariant.withOpacity(0.30),
            ),
          ),
          child: Text(
            'Sign Out of Account',
            style: AppTextStyles.labelLg.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
