import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entity/attachment_entity.dart';
import '../repository/attachment_repository.dart';

class PickImageAttachmentUseCase {
  const PickImageAttachmentUseCase(this._repository);

  final IAttachmentRepository _repository;

  Future<Either<Failure, AttachmentEntity?>> call() {
    return _repository.pickImage();
  }
}
