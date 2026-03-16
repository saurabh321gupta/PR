import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../services/storage_service.dart';
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
    }
  }

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
      final url = await _storageService.uploadProfilePhoto(uid, File(picked.path));

      await _firestore.collection('users').doc(uid).update({'photos': [url]});

      setState(() {
        _userModel = UserModel(
          id: _userModel!.id,
          firstName: _userModel!.firstName,
          age: _userModel!.age,
          gender: _userModel!.gender,
          bio: _userModel!.bio,
          photos: [url],
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
            content: Text('Photo updated ✓'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

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
          content: Text('Preference updated ✓'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

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

    if (mounted) FocusScope.of(context).unfocus();
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign out?'),
        content: const Text("You'll need to verify your work email to sign back in."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
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

  Future<ImageSource?> _showImageSourceDialog() {
    return showModalBottomSheet<ImageSource>(
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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Change photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.pink),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.pink),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Color _avatarColor(String name) {
    final colors = [
      Colors.pink.shade300,
      Colors.purple.shade300,
      Colors.indigo.shade300,
      Colors.teal.shade400,
      Colors.orange.shade400,
    ];
    return colors[name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'My Profile',
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : _userModel == null
              ? const Center(child: Text('No profile found.'))
              : _buildProfile(),
    );
  }

  Widget _buildProfile() {
    final user = _userModel!;
    final hasPhoto = user.photos.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ── Photo ──────────────────────────────────────────────────────
          GestureDetector(
            onTap: _changePhoto,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: _avatarColor(user.firstName),
                  backgroundImage:
                      hasPhoto ? NetworkImage(user.photos[0]) : null,
                  child: !hasPhoto
                      ? Text(
                          user.firstName.isNotEmpty
                              ? user.firstName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                if (_isSaving)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.4),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.pink,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 16),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Name + age ─────────────────────────────────────────────────
          Text(
            '${user.firstName}, ${user.age}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),

          // Verified badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, size: 14, color: Colors.green.shade600),
                const SizedBox(width: 4),
                Text(
                  'Verified Professional',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Bio ────────────────────────────────────────────────────────
          _sectionCard(
            title: 'Bio',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _bioController,
                  maxLines: 4,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Write something about yourself...',
                    counterStyle: TextStyle(fontSize: 11),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _isSaving ? null : _saveBio,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Save'),
                    style: TextButton.styleFrom(foregroundColor: Colors.pink),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Info ───────────────────────────────────────────────────────
          _sectionCard(
            title: 'Account',
            child: Column(
              children: [
                _infoRow(Icons.cake_outlined, 'Age', '${user.age}'),
                const Divider(height: 1),
                _infoRow(Icons.person_outline, 'Gender', user.gender),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.favorite_border,
                          size: 18, color: Colors.grey.shade500),
                      const SizedBox(width: 12),
                      Text('Show me',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade600)),
                      const Spacer(),
                      DropdownButton<String>(
                        value: _selectedInterest,
                        underline: const SizedBox(),
                        isDense: true,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87),
                        items: _interests
                            .map((i) => DropdownMenuItem(
                                value: i, child: Text(i)))
                            .toList(),
                        onChanged: _isSaving
                            ? null
                            : (val) {
                                if (val != null) _saveInterest(val);
                              },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                _infoRow(
                  Icons.business_outlined,
                  'Verified via',
                  user.companyDomain,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── Sign out ───────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Sign out',
                  style: TextStyle(color: Colors.red, fontSize: 15)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Text(label,
              style:
                  TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
