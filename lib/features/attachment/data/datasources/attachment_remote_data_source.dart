import 'package:file_picker/file_picker.dart';

import '../models/attachment_model.dart';

abstract class IAttachmentRemoteDataSource {
  Future<AttachmentModel?> pickImage();
}

class AttachmentRemoteDataSourceImpl implements IAttachmentRemoteDataSource {
  const AttachmentRemoteDataSourceImpl();

  @override
  Future<AttachmentModel?> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    return AttachmentModel.fromPlatformFile(result.files.first);
  }
}
