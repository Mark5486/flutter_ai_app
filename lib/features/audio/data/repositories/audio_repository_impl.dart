import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_ai_app/features/audio/data/datasources/audio_remote_data_source.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entity/audio_entity.dart';
import '../../domain/repository/audio_repository.dart';

class AudioRepositoryImpl implements IAudioRepository {
  const AudioRepositoryImpl(this._remoteDataSource);

  final IAudioRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, void>> startRecording() async {
    try {
      await _remoteDataSource.startRecording();

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Uint8List>> stopRecording() async {
    try {
      final bytes = await _remoteDataSource.stopRecording();

      return Right(bytes);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelRecording() async {
    try {
      await _remoteDataSource.cancelRecording();

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AudioEntity>> uploadAudio(Uint8List bytes) async {
    try {
      final model = await _remoteDataSource.uploadAudio(bytes);

      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
