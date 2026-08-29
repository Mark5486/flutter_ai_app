class AttachmentValidator {
  const AttachmentValidator._();

  static const Set<String> allowedImageMimeTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
  };

  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5 MB

  static void validateImage({
    required String mimeType,
    required int sizeBytes,
  }) {
    if (!allowedImageMimeTypes.contains(mimeType)) {
      throw const AttachmentValidationException(
        'صيغة الصورة غير مدعومة. المسموح: JPEG أو PNG أو WebP فقط.',
      );
    }

    if (sizeBytes <= 0) {
      throw const AttachmentValidationException('تعذر قراءة بيانات الصورة.');
    }

    if (sizeBytes > maxImageSizeBytes) {
      throw const AttachmentValidationException(
        'حجم الصورة أكبر من الحد المسموح (5 ميجابايت).',
      );
    }
  }

  static String mimeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}

class AttachmentValidationException implements Exception {
  const AttachmentValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
