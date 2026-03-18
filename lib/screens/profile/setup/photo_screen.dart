import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'bio_screen.dart';
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
  final _picker = ImagePicker();
  File? _pickedPhoto;

  Future<void> _pickPhoto() async {
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

    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _pickedPhoto = File(picked.path));
    }
  }

  void _proceed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BioScreen(
          userId: widget.userId,
          workEmail: widget.workEmail,
          city: widget.city,
          firstName: widget.firstName,
          age: widget.age,
          gender: widget.gender,
          showGender: widget.showGender,
          interestedIn: widget.interestedIn,
          photo: _pickedPhoto,
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
            const SetupProgressBar(currentStep: 4, totalSteps: 5),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),
                    const Text(
                      'Time to put a face\nto the name',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.black87, height: 1.25),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Add a photo so people can see the real you. You can always add more later.',
                      style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.5),
                    ),
                    const SizedBox(height: 32),

                    // Photo slot
                    Center(
                      child: GestureDetector(
                        onTap: _pickPhoto,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 200,
                          height: 260,
                          decoration: BoxDecoration(
                            color: _pickedPhoto != null ? null : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _pickedPhoto != null ? const Color(0xFFE91E63) : Colors.grey.shade300,
                              width: _pickedPhoto != null ? 2 : 1.5,
                            ),
                            image: _pickedPhoto != null
                                ? DecorationImage(image: FileImage(_pickedPhoto!), fit: BoxFit.cover)
                                : null,
                          ),
                          child: _pickedPhoto == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add, size: 40, color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    Text('Tap to add', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                                  ],
                                )
                              : null,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    if (_pickedPhoto != null)
                      Center(
                        child: GestureDetector(
                          onTap: _pickPhoto,
                          child: const Text('Tap photo to change', style: TextStyle(fontSize: 13, color: Color(0xFFE91E63), fontWeight: FontWeight.w500)),
                        ),
                      ),

                    const Spacer(),

                    // Photo tips
                    Row(
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 8),
                        Text('A clear face photo works best!', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                    const SizedBox(height: 16),
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
