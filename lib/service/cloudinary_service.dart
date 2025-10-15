// lib/service/cloudinary_service.dart
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/cupertino.dart';

class CloudinaryService {

  static const _cloudName    = 'dzyopb2ur';
  static const _uploadPreset = 'Avatar';

  static final _cloudinary = CloudinaryPublic(
    _cloudName,
    _uploadPreset,
    cache: false,
  );

  static Future<String?> uploadAudio({
    required String filePath,
    String folder = 'audio_messages',
  }) async {
    try {
      final res = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          filePath,
          folder: folder,
          resourceType: CloudinaryResourceType.Video,
        ),
      );
      return res.secureUrl;
    } on CloudinaryException catch (e) {
      debugPrint('Cloudinary upload error: ${e.message}');
      return null;
    }
  }



  static Future<String?> uploadAvatar({
    required String filePath,
    String folder = 'avatars',
  }) async {
    try {
      final res = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          filePath,
          folder: folder,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return res.secureUrl;
    } on CloudinaryException catch (e) {

      debugPrint('Cloudinary upload error:');
      return null;
    }
  }
}