import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;

  /// Uploads a single profile photo at a given index and returns the download URL.
  /// Stored at: profile_photos/{userId}/photo_{index}.jpg
  Future<String> uploadProfilePhoto(String userId, File imageFile, {int index = 0}) async {
    final ref = _storage
        .ref()
        .child('profile_photos')
        .child(userId)
        .child('photo_$index.jpg');

    final uploadTask = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await uploadTask.ref.getDownloadURL();
  }

  /// Uploads multiple profile photos concurrently and returns download URLs in order.
  Future<List<String>> uploadProfilePhotos(String userId, List<File> photos) async {
    final futures = <Future<String>>[];
    for (var i = 0; i < photos.length; i++) {
      futures.add(uploadProfilePhoto(userId, photos[i], index: i));
    }
    return await Future.wait(futures);
  }

  /// Deletes a specific profile photo for a user.
  Future<void> deleteProfilePhoto(String userId, {int index = 0}) async {
    try {
      await _storage
          .ref()
          .child('profile_photos')
          .child(userId)
          .child('photo_$index.jpg')
          .delete();
    } catch (_) {
      // Ignore if file doesn't exist
    }
  }
}
