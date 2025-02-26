import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;

class StorageService {
  final SupabaseClient _supabase;

  StorageService(this._supabase);

  Future<String> uploadImage(String filePath) async {
    try {
      // Baca file sebagai bytes
      final File imageFile = File(filePath);
      final Uint8List originalBytes = await imageFile.readAsBytes();

      // Decode dan kompres gambar
      final img.Image? image = img.decodeImage(originalBytes);
      if (image == null) throw Exception('Could not decode image');

      // Resize gambar jika terlalu besar
      img.Image resizedImage = image;
      if (image.width > 1024 || image.height > 1024) {
        resizedImage = img.copyResize(
          image,
          width: image.width > image.height ? 1024 : null,
          height: image.height >= image.width ? 1024 : null,
        );
      }

      // Kompres gambar ke format JPEG dengan kualitas 70%
      final compressedBytes = img.encodeJpg(resizedImage, quality: 70);

      final fileName = path.basename(filePath);
      final uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}_$fileName';

      await _supabase.storage.from('room-images').uploadBinary(
            uniqueFileName,
            compressedBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
            ),
          );

      final imageUrl =
          _supabase.storage.from('room-images').getPublicUrl(uniqueFileName);

      return imageUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}
