import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entity/attachment_entity.dart';
import '../../domain/repository/attachment_repository.dart';
import '../../domain/validators/attachment_validator.dart';
import '../datasources/attachment_remote_data_source.dart';

class AttachmentRepositoryImpl implements IAttachmentRepository {
  const AttachmentRepositoryImpl(this._remoteDataSource);

  final IAttachmentRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, AttachmentEntity?>> pickImage() async {
    try {
      final model = await _remoteDataSource.pickImage();

      return Right(model?.toEntity());
    } on AttachmentValidationException catch (e) {
      
      return Left((ServerFailure(e.toString())));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
