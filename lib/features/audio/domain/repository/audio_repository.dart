import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entity/audio_entity.dart';

abstract class IAudioRepository {
  Future<Either<Failure, void>> startRecording();

  Future<Either<Failure, Uint8List>> stopRecording();

  Future<Either<Failure, void>> cancelRecording();

  Future<Either<Failure, AudioEntity>> uploadAudio(Uint8List bytes);

  Future<Either<Failure, String>> transcribeAudio(Uint8List bytes);
}
