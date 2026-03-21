import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/user_model.dart';
import '../../../services/storage_service.dart';
import 'setup_progress_bar.dart';

class BioScreen extends StatefulWidget {
  final String userId;
  final String workEmail;
  final String city;
  final String firstName;
  final int age;
  final String gender;
  final bool showGender;
  final String interestedIn;
  final List<File> photos;
  final List<String> interests;

  const BioScreen({
    super.key,
    required this.userId,
    required this.workEmail,
    required this.city,
    required this.firstName,
    required this.age,
    required this.gender,
    required this.showGender,
    required this.interestedIn,
    required this.photos,
    required this.interests,
  });

  @override
  State<BioScreen> createState() => _BioScreenState();
}

class _BioScreenState extends State<BioScreen> {
  final _bioController = TextEditingController();
  final _storageService = StorageService();
  bool _isLoading = false;
  String? _bioError;

  String get _companyDomain => widget.workEmail.split('@').last;

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final bio = _bioController.text.trim();
    if (bio.isEmpty) {
      setState(() => _bioError = 'Please write something about yourself');
      return;
    }

    setState(() {
      _isLoading = true;
      _bioError = null;
    });

    List<String> photoUrls = [];
    if (widget.photos.isNotEmpty) {
      try {
        photoUrls = await _storageService.uploadProfilePhotos(
          widget.userId,
          widget.photos,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo upload failed: $e'), backgroundColor: Colors.orange),
        );
        setState(() => _isLoading = false);
        return;
      }
    }

    final user = UserModel(
      id: widget.userId,
      firstName: widget.firstName,
      age: widget.age,
      gender: widget.gender,
      interestedIn: widget.interestedIn,
      bio: bio,
      photos: photoUrls,
      interests: widget.interests,
      city: widget.city,
      companyDomain: _companyDomain,
      workVerified: true,
      industryCategory: '',
      role: '',
      showIndustry: true,
      showRole: true,
      createdAt: DateTime.now(),
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .set(user.toMap());

    setState(() => _isLoading = false);

    if (!mounted) return;
    // Pop all onboarding screens back to _AuthGate root.
    // _AuthGate detects the signed-in user + profile and shows HomeScreen.
    // Using pushAndRemoveUntil would destroy _AuthGate and break sign-out.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SetupProgressBar(currentStep: 6, totalSteps: 6),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 28),
                        const Text(
                          'Almost there —\nsell yourself a little ✍️',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.black87, height: 1.25),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'A good bio is the difference between "meh" and "tell me more".',
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.5),
                        ),
                        const SizedBox(height: 28),

                        TextField(
                          controller: _bioController,
                          maxLines: 5,
                          maxLength: 200,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                          decoration: InputDecoration(
                            hintText: 'Monday meetings survivor. Weekend hiking enthusiast. Makes a mean pasta.',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE91E63), width: 2)),
                            errorText: _bioError,
                          ),
                          onChanged: (_) {
                            if (_bioError != null) setState(() => _bioError = null);
                          },
                        ),

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
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          disabledBackgroundColor: Colors.pink.shade200,
                          shape: const CircleBorder(), padding: EdgeInsets.zero, elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Icon(Icons.check, color: Colors.white, size: 26),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.white.withValues(alpha: 0.8),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFFE91E63)),
                      SizedBox(height: 16),
                      Text('Uploading your photos & creating your profile...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black54)),
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
