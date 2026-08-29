import 'package:dartz/dartz.dart';
import 'package:flutter_ai_app/core/errors/failures.dart';
import 'package:flutter_ai_app/features/attachment/domain/entity/attachment_entity.dart';
import 'package:flutter_ai_app/features/attachment/domain/repository/attachment_repository.dart';

class PickImageAttachmentUseCase {
  final IAttachmentRepository repository;

  PickImageAttachmentUseCase(this.repository);

  Future<Either<Failure, AttachmentEntity?>> call() {
    return repository.pickImage();
  }
}
