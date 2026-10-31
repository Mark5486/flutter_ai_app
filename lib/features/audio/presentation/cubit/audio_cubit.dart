import 'package:flutter_ai_app/features/audio/domain/usecases/cancel_recording_usecase.dart';
import 'package:flutter_ai_app/features/audio/domain/usecases/start_recording_usecase.dart';
import 'package:flutter_ai_app/features/audio/domain/usecases/stop_recording_usecase.dart'
    show StopRecordingUseCase;
import 'package:flutter_ai_app/features/audio/domain/usecases/upload_audio_usecase.dart';
import 'package:flutter_ai_app/features/audio/domain/usecases/transcribe_audio_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'audio_state.dart';

class AudioCubit extends Cubit<AudioState> {
  AudioCubit(
    this._startRecordingUseCase,
    this._stopRecordingUseCase,
    this._cancelRecordingUseCase,
    this._uploadAudioUseCase,
    this._transcribeAudioUseCase,
  ) : super(AudioIdle());

  final StartRecordingUseCase _startRecordingUseCase;
  final StopRecordingUseCase _stopRecordingUseCase;
  final CancelRecordingUseCase _cancelRecordingUseCase;
  final UploadAudioUseCase _uploadAudioUseCase;
  final TranscribeAudioUseCase _transcribeAudioUseCase;

  Future<void> startRecording() async {
    if (state is! AudioIdle && state is! AudioFailure) return;
    final result = await _startRecordingUseCase();

    result.fold(
      (failure) => emit(AudioFailure(failure.message)),
      (_) => emit(AudioRecording()),
    );
  }

  Future<void> stopRecording() async {
    if (state is! AudioRecording) return;
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

  Future<void> stopAndUpload() async {
    if (state is! AudioRecording) return;
    await stopRecording();
    if (state is AudioRecorded) await uploadAudio();
  }

  Future<void> uploadAudio() async {
    final currentState = state;

    if (currentState is! AudioRecorded) return;

    final bytes = currentState.bytes;

    emit(AudioUploading(bytes));

    final transcriptResult = await _transcribeAudioUseCase(bytes);
    final transcript = transcriptResult.fold<String?>((failure) {
      emit(AudioFailure(failure.message, bytes: bytes));
      return null;
    }, (value) => value);
    if (transcript == null || isClosed) return;

    final uploadResult = await _uploadAudioUseCase(bytes);
    uploadResult.fold(
      (failure) => emit(AudioFailure(failure.message, bytes: bytes)),
      (audio) => emit(AudioReady(audio, transcript)),
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

  @override
  Future<void> close() async {
    if (state is AudioRecording) {
      await _cancelRecordingUseCase();
    }
    return super.close();
  }
}
