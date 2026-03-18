import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'interests_picker_screen.dart';
import 'setup_progress_bar.dart';

class PhotoScreen extends StatefulWidget {
  final String userId;
  final String workEmail;
  final String city;
  final String firstName;
  final int age;
  final String gender;
  final bool showGender;
  final String interestedIn;

  const PhotoScreen({
    super.key,
    required this.userId,
    required this.workEmail,
    required this.city,
    required this.firstName,
    required this.age,
    required this.gender,
    required this.showGender,
    required this.interestedIn,
  });

  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  static const int _minPhotos = 3;
  static const int _maxPhotos = 5;

  final _picker = ImagePicker();
  final List<File> _photos = [];

  bool get _canProceed => _photos.length >= _minPhotos;

  /// Pick + crop flow for a single photo
  Future<File?> _pickAndCrop() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text('Add a photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFE91E63)),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFE91E63)),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return null;

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1600,
      imageQuality: 90,
    );
    if (picked == null) return null;

    // Crop to 3:4 portrait ratio
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 3, ratioY: 4),
      compressQuality: 85,
      maxWidth: 900,
      maxHeight: 1200,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop your photo',
          toolbarColor: const Color(0xFFE91E63),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: const Color(0xFFE91E63),
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Crop your photo',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
        ),
      ],
    );

    if (cropped == null) return null;
    return File(cropped.path);
  }

  /// Add a new photo to an empty slot
  Future<void> _addPhoto() async {
    if (_photos.length >= _maxPhotos) return;
    final file = await _pickAndCrop();
    if (file != null) {
      setState(() => _photos.add(file));
    }
  }

  /// Replace an existing photo at index
  Future<void> _replacePhoto(int index) async {
    final file = await _pickAndCrop();
    if (file != null) {
      setState(() => _photos[index] = file);
    }
  }

  /// Remove a photo at index
  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  void _proceed() {
    if (!_canProceed) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InterestsPickerScreen(
          userId: widget.userId,
          workEmail: widget.workEmail,
          city: widget.city,
          firstName: widget.firstName,
          age: widget.age,
          gender: widget.gender,
          showGender: widget.showGender,
          interestedIn: widget.interestedIn,
          photos: List.from(_photos),
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
            const SetupProgressBar(currentStep: 4, totalSteps: 6),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),
                    const Text(
                      'Show them what\nthey\'re missing 📸',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.black87, height: 1.25),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Profiles with photos get 9x more attention. Just saying.',
                      style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add at least $_minPhotos photos (up to $_maxPhotos)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 24),

                    // Photo grid — 2 columns, 3 rows max
                    Expanded(
                      child: _buildPhotoGrid(),
                    ),

                    // Counter + tip
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          // Photo counter pills
                          ...List.generate(_maxPhotos, (i) {
                            final filled = i < _photos.length;
                            return Container(
                              width: 8, height: 8,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: filled ? const Color(0xFFE91E63) : Colors.grey.shade300,
                              ),
                            );
                          }),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _photos.length < _minPhotos
                                  ? '${_minPhotos - _photos.length} more to go'
                                  : _photos.length < _maxPhotos
                                      ? 'Looking good! You can add ${_maxPhotos - _photos.length} more'
                                      : 'All slots filled — you\'re all set!',
                              style: TextStyle(
                                fontSize: 12,
                                color: _photos.length < _minPhotos ? Colors.orange.shade700 : Colors.grey.shade600,
                                fontWeight: _photos.length < _minPhotos ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Proceed button
            Padding(
              padding: const EdgeInsets.only(right: 28, bottom: 24),
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    // Total slots: filled photos + 1 empty (if < max)
    final totalSlots = (_photos.length < _maxPhotos) ? _photos.length + 1 : _photos.length;

    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 3 / 4, // Match crop ratio
      ),
      itemCount: totalSlots,
      itemBuilder: (context, index) {
        if (index < _photos.length) {
          return _buildFilledSlot(index);
        } else {
          return _buildEmptySlot(index);
        }
      },
    );
  }

  Widget _buildFilledSlot(int index) {
    final isMain = index == 0;
    return GestureDetector(
      onTap: () => _showPhotoOptions(index),
      child: Stack(
        children: [
          // Photo
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isMain ? const Color(0xFFE91E63) : Colors.grey.shade300,
                width: isMain ? 2.5 : 1.5,
              ),
              image: DecorationImage(
                image: FileImage(_photos[index]),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // "Main" badge on first photo
          if (isMain)
            Positioned(
              bottom: 6, left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'MAIN',
                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ),
            ),

          // Delete button
          Positioned(
            top: 4, right: 4,
            child: GestureDetector(
              onTap: () => _removePhoto(index),
              child: Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySlot(int index) {
    final isRequired = index < _minPhotos;
    return GestureDetector(
      onTap: _addPhoto,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRequired ? const Color(0xFFE91E63).withValues(alpha: 0.4) : Colors.grey.shade300,
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: isRequired ? const Color(0xFFE91E63).withValues(alpha: 0.1) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                size: 20,
                color: isRequired ? const Color(0xFFE91E63) : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isRequired ? 'Required' : 'Optional',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isRequired ? const Color(0xFFE91E63).withValues(alpha: 0.7) : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoOptions(int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text('Photo options', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: Color(0xFFE91E63)),
              title: const Text('Replace this photo'),
              onTap: () {
                Navigator.pop(context);
                _replacePhoto(index);
              },
            ),
            if (index > 0)
              ListTile(
                leading: const Icon(Icons.star_outline, color: Color(0xFFE91E63)),
                title: const Text('Make this my main photo'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    final photo = _photos.removeAt(index);
                    _photos.insert(0, photo);
                  });
                },
              ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
              title: Text('Remove', style: TextStyle(color: Colors.red.shade400)),
              onTap: () {
                Navigator.pop(context);
                _removePhoto(index);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
