import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repository/audio_repository.dart';

class CancelRecordingUseCase {
  const CancelRecordingUseCase(this._repository);

  final IAudioRepository _repository;

  Future<Either<Failure, void>> call() {
    return _repository.cancelRecording();
  }
}
