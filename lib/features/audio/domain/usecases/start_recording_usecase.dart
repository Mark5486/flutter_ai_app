import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repository/audio_repository.dart';

class StartRecordingUseCase {
  const StartRecordingUseCase(this._repository);

  final IAudioRepository _repository;

  Future<Either<Failure, void>> call() {
    return _repository.startRecording();
  }
}
