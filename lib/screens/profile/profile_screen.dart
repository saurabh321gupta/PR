import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

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

  // Photo carousel
  final PageController _photoPageController = PageController();
  int _currentPhotoIndex = 0;

  // Edit mode controllers
  final _bioController = TextEditingController();
  String _selectedInterest = 'Everyone';
  final List<String> _interestOptions = ['Men', 'Women', 'Everyone'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _photoPageController.dispose();
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
      setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Photo management
  // ---------------------------------------------------------------------------

  Future<void> _addPhoto() async {
    if (_userModel == null) return;
    if (_userModel!.photos.length >= 5) {
      _showSnack('Maximum 5 photos allowed', isError: true);
      return;
    }

    final source = await _showImageSourceDialog();
    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1600,
      imageQuality: 90,
    );
    if (picked == null) return;

    // Crop to 3:4 portrait
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 3, ratioY: 4),
      compressQuality: 85,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Adjust Photo',
          toolbarColor: AppColors.onSurface,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: AppColors.primary,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Adjust Photo',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );
    if (cropped == null) return;

    setState(() => _isSaving = true);

    try {
      final uid = _auth.currentUser!.uid;
      final index = _userModel!.photos.length;
      final url = await _storageService.uploadProfilePhoto(
        uid,
        File(cropped.path),
        index: index,
      );

      final updatedPhotos = [..._userModel!.photos, url];
      await _firestore
          .collection('users')
          .doc(uid)
          .update({'photos': updatedPhotos});

      setState(() {
        _userModel = _userModel!._copyWith(photos: updatedPhotos);
      });
      _showSnack('Photo added');
    } catch (e) {
      _showSnack('Upload failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _replacePhoto(int index) async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1600,
      imageQuality: 90,
    );
    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 3, ratioY: 4),
      compressQuality: 85,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Adjust Photo',
          toolbarColor: AppColors.onSurface,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: AppColors.primary,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Adjust Photo',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );
    if (cropped == null) return;

    setState(() => _isSaving = true);

    try {
      final uid = _auth.currentUser!.uid;
      final url = await _storageService.uploadProfilePhoto(
        uid,
        File(cropped.path),
        index: index,
      );

      final updatedPhotos = List<String>.from(_userModel!.photos);
      updatedPhotos[index] = url;
      await _firestore
          .collection('users')
          .doc(uid)
          .update({'photos': updatedPhotos});

      setState(() {
        _userModel = _userModel!._copyWith(photos: updatedPhotos);
      });
      _showSnack('Photo updated');
    } catch (e) {
      _showSnack('Upload failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deletePhoto(int index) async {
    if (_userModel!.photos.length <= 3) {
      _showSnack('You need at least 3 photos', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uid = _auth.currentUser!.uid;
      final updatedPhotos = List<String>.from(_userModel!.photos);
      updatedPhotos.removeAt(index);

      await _firestore
          .collection('users')
          .doc(uid)
          .update({'photos': updatedPhotos});

      setState(() {
        _userModel = _userModel!._copyWith(photos: updatedPhotos);
        if (_currentPhotoIndex >= updatedPhotos.length) {
          _currentPhotoIndex = updatedPhotos.length - 1;
        }
      });
      _showSnack('Photo removed');
    } catch (e) {
      _showSnack('Failed to remove: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showPhotoOptions(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
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
            Text('Photo ${index + 1}', style: AppTextStyles.headlineSm),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.swap_horiz_rounded,
                  color: AppColors.primary),
              title: Text('Replace this photo', style: AppTextStyles.labelLg),
              onTap: () {
                Navigator.pop(context);
                _replacePhoto(index);
              },
            ),
            if (index > 0)
              ListTile(
                leading:
                    const Icon(Icons.star_rounded, color: AppColors.primary),
                title: Text('Make main photo', style: AppTextStyles.labelLg),
                onTap: () {
                  Navigator.pop(context);
                  _makeMainPhoto(index);
                },
              ),
            if (_userModel!.photos.length > 3)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error),
                title: Text('Remove photo',
                    style: AppTextStyles.labelLg
                        .copyWith(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _deletePhoto(index);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _makeMainPhoto(int index) async {
    setState(() => _isSaving = true);
    try {
      final uid = _auth.currentUser!.uid;
      final updatedPhotos = List<String>.from(_userModel!.photos);
      final photo = updatedPhotos.removeAt(index);
      updatedPhotos.insert(0, photo);

      await _firestore
          .collection('users')
          .doc(uid)
          .update({'photos': updatedPhotos});

      setState(() {
        _userModel = _userModel!._copyWith(photos: updatedPhotos);
        _currentPhotoIndex = 0;
        _photoPageController.jumpToPage(0);
      });
      _showSnack('Main photo updated');
    } catch (e) {
      _showSnack('Failed: $e', isError: true);
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
    final uid = _auth.currentUser!.uid;
    await _firestore
        .collection('users')
        .doc(uid)
        .update({'interestedIn': newInterest});
    setState(() {
      _selectedInterest = newInterest;
      _isSaving = false;
    });
    if (mounted) _showSnack('Preference updated');
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
      _userModel = _userModel!._copyWith(bio: newBio);
      _isSaving = false;
    });

    if (mounted) {
      Navigator.pop(context);
      FocusScope.of(context).unfocus();
    }
  }

  // ---------------------------------------------------------------------------
  // Sign-out
  // ---------------------------------------------------------------------------

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.onSurface.withAlpha(100),
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
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
    // No manual navigation needed — _AuthGate listens to authStateChanges()
    // and automatically switches to LandingScreen when user becomes null.
    // Using pushAndRemoveUntil here would destroy _AuthGate and break
    // subsequent sign-in flows.
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.tertiary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  Future<ImageSource?> _showImageSourceDialog() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
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
            Text('Choose source', style: AppTextStyles.headlineSm),
            const SizedBox(height: 8),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppColors.primary),
              title: Text('Choose from gallery', style: AppTextStyles.labelLg),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading:
                  const Icon(Icons.camera_alt, color: AppColors.primary),
              title: Text('Take a photo', style: AppTextStyles.labelLg),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
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
                  child:
                      Text('No profile found.', style: AppTextStyles.bodyLg))
              : Stack(
                  children: [
                    _buildBody(),
                    _buildGlassmorphicHeader(),
                  ],
                ),
    );
  }

  // ---------------------------------------------------------------------------
  // Glassmorphic header
  // ---------------------------------------------------------------------------

  Widget _buildGlassmorphicHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: AppColors.surface.withAlpha(204), // 80%
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.menu,
                            color: AppColors.primary),
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
                Container(
                  height: 1,
                  color: AppColors.outlineVariant.withAlpha(77), // 30%
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Body
  // ---------------------------------------------------------------------------

  Widget _buildBody() {
    final topPadding = MediaQuery.of(context).padding.top + 56 + 1;

    return SingleChildScrollView(
      padding: EdgeInsets.only(top: topPadding + 16, bottom: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Photo carousel
          _buildPhotoCarousel(),
          const SizedBox(height: 28),

          // 2. The Executive Summary (bio)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildExecutiveSummary(),
          ),
          const SizedBox(height: 16),

          // 3. Interests chips
          if (_userModel!.interests.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildInterestsSection(),
            ),
            const SizedBox(height: 16),
          ],

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
  // 1. Photo Carousel — swipeable through all photos
  // ---------------------------------------------------------------------------

  Widget _buildPhotoCarousel() {
    final user = _userModel!;
    final photos = user.photos;
    final hasPhotos = photos.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Photo card
          AspectRatio(
            aspectRatio: 3 / 4,
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
                  // Page view of photos
                  if (hasPhotos)
                    PageView.builder(
                      controller: _photoPageController,
                      itemCount: photos.length,
                      onPageChanged: (i) =>
                          setState(() => _currentPhotoIndex = i),
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => _openPhotoViewer(i),
                        onLongPress: () => _showPhotoOptions(i),
                        child: Image.network(
                          photos[i],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _photoPlaceholder(user),
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: AppColors.surfaceContainerHigh,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  else
                    _photoPlaceholder(user),

                  // Saving overlay
                  if (_isSaving)
                    Container(
                      color: AppColors.onSurface.withAlpha(89), // 35%
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),

                  // Top segment indicators (like Instagram stories)
                  if (hasPhotos && photos.length > 1)
                    Positioned(
                      top: 12,
                      left: 16,
                      right: 16,
                      child: Row(
                        children: List.generate(photos.length, (i) {
                          return Expanded(
                            child: Container(
                              height: 3,
                              margin: EdgeInsets.only(
                                  right: i < photos.length - 1 ? 4 : 0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: i == _currentPhotoIndex
                                    ? Colors.white
                                    : Colors.white.withAlpha(102), // 40%
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                  // Bottom scrim gradient
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
                            AppColors.onSurface.withAlpha(153), // 60%
                            AppColors.onSurface.withAlpha(0),
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
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (user.city.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded,
                                  color: Colors.white.withAlpha(204),
                                  size: 16),
                              const SizedBox(width: 4),
                              Text(
                                user.city,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: Colors.white.withAlpha(217), // 85%
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Tap left/right zones for quick photo navigation
                  if (hasPhotos && photos.length > 1) ...[
                    // Tap left half → previous photo
                    Positioned(
                      left: 0,
                      top: 40,
                      bottom: 80,
                      width: MediaQuery.of(context).size.width * 0.3,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          if (_currentPhotoIndex > 0) {
                            _photoPageController.animateToPage(
                              _currentPhotoIndex - 1,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: const SizedBox.expand(),
                      ),
                    ),
                    // Tap right half → next photo
                    Positioned(
                      right: 0,
                      top: 40,
                      bottom: 80,
                      width: MediaQuery.of(context).size.width * 0.3,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          if (_currentPhotoIndex < photos.length - 1) {
                            _photoPageController.animateToPage(
                              _currentPhotoIndex + 1,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Photo count badge — top right
          if (hasPhotos)
            Positioned(
              right: 12,
              top: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.onSurface.withAlpha(140),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '${_currentPhotoIndex + 1}/${photos.length}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Edit FAB
          Positioned(
            right: 16,
            bottom: -24,
            child: GestureDetector(
              onTap: _showPhotoManagementSheet,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.editorialGradient,
                  boxShadow: AppShadows.fab,
                ),
                child:
                    const Icon(Icons.edit_rounded, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPhotoManagementSheet() {
    final photos = _userModel!.photos;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
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
            Text('Manage Photos', style: AppTextStyles.headlineSm),
            const SizedBox(height: 4),
            Text(
              '${photos.length}/5 photos • Long press any photo to edit',
              style: AppTextStyles.bodySm,
            ),
            const SizedBox(height: 16),
            if (photos.length < 5)
              ListTile(
                leading: const Icon(Icons.add_photo_alternate_rounded,
                    color: AppColors.primary),
                title: Text('Add a new photo', style: AppTextStyles.labelLg),
                subtitle: Text(
                  '${5 - photos.length} slots remaining',
                  style: AppTextStyles.bodySm,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _addPhoto();
                },
              ),
            ListTile(
              leading: const Icon(Icons.swap_horiz_rounded,
                  color: AppColors.primary),
              title: Text('Replace current photo', style: AppTextStyles.labelLg),
              subtitle: Text(
                'Photo ${_currentPhotoIndex + 1} of ${photos.length}',
                style: AppTextStyles.bodySm,
              ),
              onTap: () {
                Navigator.pop(context);
                _replacePhoto(_currentPhotoIndex);
              },
            ),
            if (photos.length > 3)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error),
                title: Text('Remove current photo',
                    style: AppTextStyles.labelLg
                        .copyWith(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _deletePhoto(_currentPhotoIndex);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openPhotoViewer(int initialIndex) {
    final photos = _userModel!.photos;
    if (photos.isEmpty) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => _FullScreenPhotoViewer(
          photos: photos,
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Widget _photoPlaceholder(UserModel user) {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_a_photo_rounded,
                size: 48, color: AppColors.primary.withAlpha(77)),
            const SizedBox(height: 8),
            Text(
              'Add photos',
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.primary.withAlpha(128)),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. The Executive Summary (bio)
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
            if (user.bio.isNotEmpty)
              Text(
                user.bio,
                style: AppTextStyles.bodyLg.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.7,
                ),
              )
            else
              Text(
                'Tap to write something about yourself...',
                style: AppTextStyles.bodyLg.copyWith(
                  color: AppColors.outlineVariant,
                  height: 1.7,
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.edit_outlined,
                    size: 16, color: AppColors.outlineVariant),
                const SizedBox(width: 4),
                Text(
                  'Edit',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.outlineVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bio editor bottom sheet
  // ---------------------------------------------------------------------------

  void _showBioEditor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
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
              style:
                  AppTextStyles.bodyLg.copyWith(color: AppColors.onSurface),
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

  // ---------------------------------------------------------------------------
  // 3. Interests section
  // ---------------------------------------------------------------------------

  Widget _buildInterestsSection() {
    final interests = _userModel!.interests;

    return GestureDetector(
      onTap: _showInterestsEditor,
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
                const Icon(Icons.interests_rounded,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Text(
                  'What I\'m Into',
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const Spacer(),
                Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.outlineVariant),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: interests.map((interest) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: AppColors.outlineVariant.withAlpha(128),
                    ),
                  ),
                  child: Text(
                    interest,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurface,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Quick Stats
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
          if (user.city.isNotEmpty)
            _statRow(
              icon: Icons.location_on_outlined,
              label: 'LOCATION',
              value: user.city,
            ),
          if (user.city.isNotEmpty) const SizedBox(height: 16),
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
            icon: Icons.favorite_outline_rounded,
            label: 'INTERESTED IN',
            value: _selectedInterest,
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
        Expanded(
          child: Column(
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
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 20),
        _settingRow(
          icon: Icons.explore_outlined,
          title: 'Discovery Settings',
          subtitle: 'Show me: $_selectedInterest',
          onTap: _showDiscoverySheet,
        ),
        const SizedBox(height: 16),
        _settingRow(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'Manage push notifications',
          onTap: () {},
        ),
        const SizedBox(height: 16),
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
            const Icon(Icons.chevron_right,
                color: AppColors.outlineVariant),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Interests editor
  // ---------------------------------------------------------------------------

  void _showInterestsEditor() {
    final currentInterests = Set<String>.from(_userModel!.interests);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => _InterestsEditorSheet(
        selected: currentInterests,
        onSave: (updated) async {
          Navigator.pop(ctx);
          setState(() => _isSaving = true);
          final uid = _auth.currentUser!.uid;
          final list = updated.toList();
          await _firestore
              .collection('users')
              .doc(uid)
              .update({'interests': list});
          setState(() {
            _userModel = _userModel!._copyWith(interests: list);
            _isSaving = false;
          });
          _showSnack('Interests updated');
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Discovery sheet
  // ---------------------------------------------------------------------------

  void _showDiscoverySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
              ..._interestOptions.map((interest) {
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
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                        border: isSelected
                            ? Border.all(
                                color: AppColors.primary, width: 2)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Text(
                            interest,
                            style: AppTextStyles.labelLg.copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.primary, size: 22),
                        ],
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
  // 6. Sign Out
  // ---------------------------------------------------------------------------

  Widget _buildSignOutButton() {
    return Center(
      child: GestureDetector(
        onTap: _signOut,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: AppColors.outlineVariant.withAlpha(77),
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

// =============================================================================
// Full-screen photo viewer with swipe
// =============================================================================

class _FullScreenPhotoViewer extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const _FullScreenPhotoViewer({
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<_FullScreenPhotoViewer> createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<_FullScreenPhotoViewer> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Swipeable photos
          PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 1.0,
              maxScale: 3.0,
              child: Center(
                child: Image.network(
                  widget.photos[i],
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(128),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 22),
              ),
            ),
          ),

          // Photo counter
          if (widget.photos.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.photos.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i == _currentIndex ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: i == _currentIndex
                          ? Colors.white
                          : Colors.white.withAlpha(102),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Interests editor sheet (reuses the same interest list from setup)
// =============================================================================

const List<Map<String, String>> _allInterests = [
  {'label': 'Foodie', 'emoji': '🍕'},
  {'label': 'Coffee', 'emoji': '☕'},
  {'label': 'Wine', 'emoji': '🍷'},
  {'label': 'Cooking', 'emoji': '👨‍🍳'},
  {'label': 'Baking', 'emoji': '🧁'},
  {'label': 'Vegetarian', 'emoji': '🥗'},
  {'label': 'Brunch', 'emoji': '🥞'},
  {'label': 'Craft beer', 'emoji': '🍺'},
  {'label': 'Gym', 'emoji': '🏋️'},
  {'label': 'Running', 'emoji': '🏃'},
  {'label': 'Yoga', 'emoji': '🧘'},
  {'label': 'Hiking', 'emoji': '🥾'},
  {'label': 'Cycling', 'emoji': '🚴'},
  {'label': 'Swimming', 'emoji': '🏊'},
  {'label': 'Camping', 'emoji': '⛺'},
  {'label': 'Cricket', 'emoji': '🏏'},
  {'label': 'Live music', 'emoji': '🎵'},
  {'label': 'Concerts', 'emoji': '🎤'},
  {'label': 'Dancing', 'emoji': '💃'},
  {'label': 'Art', 'emoji': '🎨'},
  {'label': 'Photography', 'emoji': '📸'},
  {'label': 'Writing', 'emoji': '✍️'},
  {'label': 'Singing', 'emoji': '🎙️'},
  {'label': 'Bollywood', 'emoji': '🎬'},
  {'label': 'Netflix', 'emoji': '📺'},
  {'label': 'Anime', 'emoji': '🐉'},
  {'label': 'Gaming', 'emoji': '🎮'},
  {'label': 'Reading', 'emoji': '📚'},
  {'label': 'Podcasts', 'emoji': '🎧'},
  {'label': 'Standup comedy', 'emoji': '😂'},
  {'label': 'Horror', 'emoji': '👻'},
  {'label': 'Memes', 'emoji': '🤣'},
  {'label': 'Travel', 'emoji': '✈️'},
  {'label': 'Dogs', 'emoji': '🐕'},
  {'label': 'Cats', 'emoji': '🐈'},
  {'label': 'Gardening', 'emoji': '🌱'},
  {'label': 'Astrology', 'emoji': '♈'},
  {'label': 'Spirituality', 'emoji': '🧿'},
  {'label': 'Volunteering', 'emoji': '🤝'},
  {'label': 'Road trips', 'emoji': '🚗'},
  {'label': 'Startups', 'emoji': '🚀'},
  {'label': 'Investing', 'emoji': '📈'},
  {'label': 'Tech', 'emoji': '💻'},
  {'label': 'Design', 'emoji': '🎯'},
  {'label': 'Side projects', 'emoji': '⚡'},
  {'label': 'AI', 'emoji': '🤖'},
  {'label': 'Board games', 'emoji': '🎲'},
  {'label': 'Parties', 'emoji': '🎉'},
  {'label': 'Karaoke', 'emoji': '🎤'},
  {'label': 'Deep talks', 'emoji': '💭'},
  {'label': 'Sarcasm', 'emoji': '😏'},
  {'label': 'Night owl', 'emoji': '🦉'},
  {'label': 'Early bird', 'emoji': '🌅'},
];

class _InterestsEditorSheet extends StatefulWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onSave;

  const _InterestsEditorSheet({
    required this.selected,
    required this.onSave,
  });

  @override
  State<_InterestsEditorSheet> createState() => _InterestsEditorSheetState();
}

class _InterestsEditorSheetState extends State<_InterestsEditorSheet> {
  late final Set<String> _selected;
  static const int _min = 3;
  static const int _max = 5;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.selected);
  }

  void _toggle(String label) {
    setState(() {
      if (_selected.contains(label)) {
        _selected.remove(label);
      } else if (_selected.length < _max) {
        _selected.add(label);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
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
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Edit Interests', style: AppTextStyles.headlineSm),
                const Spacer(),
                Text(
                  '${_selected.length}/$_max',
                  style: AppTextStyles.labelLg.copyWith(
                    color: _selected.length >= _min
                        ? AppColors.primary
                        : AppColors.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pick $_min–$_max things you\'re into',
                style: AppTextStyles.bodySm,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: _allInterests.map((interest) {
                    final label = interest['label']!;
                    final emoji = interest['emoji']!;
                    final isSelected = _selected.contains(label);
                    final isMaxed = _selected.length >= _max && !isSelected;

                    return GestureDetector(
                      onTap: isMaxed ? null : () => _toggle(label),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withAlpha(26)
                              : isMaxed
                                  ? AppColors.surfaceContainerHigh
                                  : AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : isMaxed
                                    ? AppColors.outlineVariant.withAlpha(64)
                                    : AppColors.outlineVariant.withAlpha(128),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(emoji,
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(
                              label,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? AppColors.primary
                                    : isMaxed
                                        ? AppColors.outline
                                        : AppColors.onSurface,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.check,
                                  size: 16, color: AppColors.primary),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selected.length >= _min
                    ? () => widget.onSave(_selected)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  disabledBackgroundColor: AppColors.surfaceContainerHigh,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
                child: Text(
                  _selected.length < _min
                      ? 'Pick ${_min - _selected.length} more'
                      : 'Save Interests',
                  style: AppTextStyles.labelLg.copyWith(
                    color: _selected.length >= _min
                        ? AppColors.onPrimary
                        : AppColors.outline,
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Extension: copyWith helper for UserModel
// =============================================================================

extension _UserModelCopyWith on UserModel {
  UserModel _copyWith({
    String? firstName,
    int? age,
    String? gender,
    String? interestedIn,
    String? bio,
    List<String>? photos,
    List<String>? interests,
    String? city,
    String? companyDomain,
    bool? workVerified,
    String? industryCategory,
    String? role,
    bool? showIndustry,
    bool? showRole,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id,
      firstName: firstName ?? this.firstName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      interestedIn: interestedIn ?? this.interestedIn,
      bio: bio ?? this.bio,
      photos: photos ?? this.photos,
      interests: interests ?? this.interests,
      city: city ?? this.city,
      companyDomain: companyDomain ?? this.companyDomain,
      workVerified: workVerified ?? this.workVerified,
      industryCategory: industryCategory ?? this.industryCategory,
      role: role ?? this.role,
      showIndustry: showIndustry ?? this.showIndustry,
      showRole: showRole ?? this.showRole,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
