import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;

  /// Uploads a profile photo and returns the public download URL.
  /// Stored at: profile_photos/{userId}/photo_0.jpg
  Future<String> uploadProfilePhoto(String userId, File imageFile) async {
    final ref = _storage
        .ref()
        .child('profile_photos')
        .child(userId)
        .child('photo_0.jpg');

    final uploadTask = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await uploadTask.ref.getDownloadURL();
  }

  /// Deletes the profile photo for a user.
  Future<void> deleteProfilePhoto(String userId) async {
    try {
      await _storage
          .ref()
          .child('profile_photos')
          .child(userId)
          .child('photo_0.jpg')
          .delete();
    } catch (_) {
      // Ignore if file doesn't exist
    }
  }
}
