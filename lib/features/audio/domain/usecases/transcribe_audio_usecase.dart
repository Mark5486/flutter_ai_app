import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repository/audio_repository.dart';

class TranscribeAudioUseCase {
  const TranscribeAudioUseCase(this._repository);

  final IAudioRepository _repository;

  Future<Either<Failure, String>> call(Uint8List bytes) {
    return _repository.transcribeAudio(bytes);
  }
}
