import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

/// Thrown when an upload fails; [message] is safe to show to the user.
class UploadException implements Exception {
  const UploadException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Uploads photos to Cloudinary with an UNSIGNED preset, so no secret ever
/// ships in the app. Create the preset in Cloudinary: Settings > Upload >
/// Upload presets > Add, signing mode "Unsigned", then fill in the two
/// values below.
class CloudinaryService {
  CloudinaryService({Dio? dio}) : _dio = dio ?? Dio();

  /// Your Cloudinary "cloud name" (dashboard top-left). Not a secret.
  static const cloudName = 'YOUR_CLOUD_NAME';

  /// Name of the unsigned upload preset. Not a secret.
  static const uploadPreset = 'YOUR_UNSIGNED_PRESET';

  static const _maxBytes = 10 * 1024 * 1024;

  final Dio _dio;

  bool get isConfigured =>
      cloudName != 'YOUR_CLOUD_NAME' && uploadPreset != 'YOUR_UNSIGNED_PRESET';

  /// Uploads [file] and returns its https URL. [onProgress] gets 0.0 to 1.0
  /// while the bytes are going up.
  Future<String> upload(XFile file, {void Function(double)? onProgress}) async {
    if (!isConfigured) {
      throw const UploadException(
          'Photo upload is not set up yet (Cloudinary name / preset missing).');
    }
    final bytes = await file.readAsBytes(); // works on mobile and web
    if (bytes.length > _maxBytes) {
      throw const UploadException('That photo is too large (max 10 MB).');
    }

    final form = FormData.fromMap({
      'upload_preset': uploadPreset,
      'file': MultipartFile.fromBytes(bytes,
          filename: file.name.isEmpty ? 'photo.jpg' : file.name),
    });

    try {
      final res = await _dio.post<Map<String, dynamic>>(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
        data: form,
        onSendProgress: (sent, total) {
          if (total > 0) onProgress?.call(sent / total);
        },
      );
      final url = res.data?['secure_url'] as String?;
      if (url == null || url.isEmpty) {
        throw const UploadException('Upload finished but no link came back.');
      }
      return url;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const UploadException(
            'Could not reach the upload service. Check your connection.');
      }
      throw const UploadException('The photo could not be uploaded. Try again.');
    }
  }
}
