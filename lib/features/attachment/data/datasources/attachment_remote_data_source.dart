import 'package:file_picker/file_picker.dart';

import '../models/attachment_model.dart';

abstract class IAttachmentRemoteDataSource {
  Future<AttachmentModel?> pickImage();
}

class AttachmentRemoteDataSourceImpl implements IAttachmentRemoteDataSource {
  const AttachmentRemoteDataSourceImpl();

  @override
  Future<AttachmentModel?> pickImage() async {
    final files = await FilePicker.pickFiles(
      type: FileType.image,
    );

    if (files.isEmpty) return null;

    return AttachmentModel.fromPlatformFile(files.first);
  }
}
