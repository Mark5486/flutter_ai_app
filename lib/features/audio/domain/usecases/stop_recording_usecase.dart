import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repository/audio_repository.dart';

class StopRecordingUseCase {
  const StopRecordingUseCase(this._repository);

  final IAudioRepository _repository;

  Future<Either<Failure, Uint8List>> call() {
    return _repository.stopRecording();
  }
}
