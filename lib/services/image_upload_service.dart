import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Uploads listing images to Firebase Storage and returns public URLs.
class ImageUploadService {
  static final ImageUploadService _instance = ImageUploadService._internal();
  factory ImageUploadService() => _instance;
  ImageUploadService._internal();

  final _storage = FirebaseStorage.instance;

  /// Uploads a file to Firebase Storage and returns the public download URL.
  /// Path: listings/{userId}/{timestamp}_{filename}
  Future<String> uploadListingImage(File file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final ext = file.path.split('.').last.toLowerCase();
    if (ext.isEmpty || ext == file.path) {
      throw Exception('Could not determine image type');
    }

    final sanitizedExt = ['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(ext) ? ext : 'jpg';
    final ref = _storage
        .ref()
        .child('listings')
        .child(user.uid)
        .child('${DateTime.now().millisecondsSinceEpoch}.$sanitizedExt');

    final task = ref.putFile(
      file,
      SettableMetadata(contentType: 'image/$sanitizedExt'),
    );

    final snapshot = await task;
    final url = await snapshot.ref.getDownloadURL();
    return url;
  }
}
