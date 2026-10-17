import 'package:flutter_ai_app/features/audio/domain/usecases/cancel_recording_usecase.dart';
import 'package:flutter_ai_app/features/audio/domain/usecases/start_recording_usecase.dart';
import 'package:flutter_ai_app/features/audio/domain/usecases/stop_recording_usecase.dart'
    show StopRecordingUseCase;
import 'package:flutter_ai_app/features/audio/domain/usecases/upload_audio_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'audio_state.dart';

class AudioCubit extends Cubit<AudioState> {
  AudioCubit(
    this._startRecordingUseCase,
    this._stopRecordingUseCase,
    this._cancelRecordingUseCase,
    this._uploadAudioUseCase,
  ) : super(AudioIdle());

  final StartRecordingUseCase _startRecordingUseCase;
  final StopRecordingUseCase _stopRecordingUseCase;
  final CancelRecordingUseCase _cancelRecordingUseCase;
  final UploadAudioUseCase _uploadAudioUseCase;

  Future<void> startRecording() async {
    final result = await _startRecordingUseCase();

    result.fold(
      (failure) => emit(AudioFailure(failure.message)),
      (_) => emit(AudioRecording()),
    );
  }

  Future<void> stopRecording() async {
    final result = await _stopRecordingUseCase();

    result.fold(
      (failure) => emit(AudioFailure(failure.message)),
      (bytes) => emit(AudioRecorded(bytes)),
    );
  }

  Future<void> cancelRecording() async {
    final result = await _cancelRecordingUseCase();

    result.fold(
      (failure) => emit(AudioFailure(failure.message)),
      (_) => emit(AudioIdle()),
    );
  }

  Future<void> uploadAudio() async {
    final currentState = state;

    if (currentState is! AudioRecorded) return;

    final bytes = currentState.bytes;

    emit(AudioUploading(bytes));

    final result = await _uploadAudioUseCase(bytes);

    result.fold(
      (failure) => emit(AudioFailure(failure.message, bytes: bytes)),
      (audio) => emit(AudioReady(audio)),
    );
  }

  void retry() {
    final currentState = state;

    if (currentState is AudioFailure && currentState.bytes != null) {
      emit(AudioRecorded(currentState.bytes!));
      return;
    }
  }

  void resetAudio() {
    emit(AudioIdle());
  }
}
