import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entity/audio_entity.dart';
import '../repository/audio_repository.dart';

class UploadAudioUseCase {
  const UploadAudioUseCase(this._repository);

  final IAudioRepository _repository;

  Future<Either<Failure, AudioEntity>> call(Uint8List bytes) {
    return _repository.uploadAudio(bytes);
  }
}
