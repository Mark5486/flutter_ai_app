import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entity/attachment_entity.dart';

abstract class IAttachmentRepository {
  Future<Either<Failure, AttachmentEntity?>> pickImage();
}
