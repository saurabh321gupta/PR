import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/user_model.dart';
import '../../../services/storage_service.dart';
import '../../home_screen.dart';
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
  final File? photo;

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
    this.photo,
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

    String? photoUrl;
    if (widget.photo != null) {
      try {
        photoUrl = await _storageService.uploadProfilePhoto(
          widget.userId,
          widget.photo!,
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
      photos: photoUrl != null ? [photoUrl] : [],
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
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
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
                const SetupProgressBar(currentStep: 5, totalSteps: 5),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 28),
                        const Text(
                          'And finally, a few\nwords about you',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.black87, height: 1.25),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Give people a reason to swipe right \u{2728}',
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
                            hintText: 'Coffee addict, trail runner, and secretly a great cook...',
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
                      Text('Creating your profile...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black54)),
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
