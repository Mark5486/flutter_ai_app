import 'package:file_picker/file_picker.dart';

import '../../domain/entity/attachment_entity.dart';
import '../../domain/validators/attachment_validator.dart';

class AttachmentModel extends AttachmentEntity {
  const AttachmentModel({
    required super.id,
    required super.name,
    required super.mimeType,
    required super.sizeBytes,
    required super.type,
    required super.bytes,
  });

  factory AttachmentModel.fromPlatformFile(PlatformFile file) {
    final bytes = file.bytes;

    if (bytes == null) {
      throw const AttachmentValidationException(
        'تعذر قراءة بيانات الصورة المختارة.',
      );
    }

    final mimeType = AttachmentValidator.mimeFromExtension(
      file.extension ?? '',
    );

    AttachmentValidator.validateImage(
      mimeType: mimeType,
      sizeBytes: bytes.length,
    );

    return AttachmentModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: file.name,
      mimeType: mimeType,
      sizeBytes: bytes.length,
      type: AttachmentType.image,
      bytes: bytes,
    );
  }

  AttachmentEntity toEntity() {
    return AttachmentEntity(
      id: id,
      name: name,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      type: type,
      bytes: bytes,
    );
  }
}
