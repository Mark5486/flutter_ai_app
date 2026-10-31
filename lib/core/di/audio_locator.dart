import 'package:record/record.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../features/audio/data/datasources/audio_remote_data_source.dart';
import '../../features/audio/data/datasources/audio_transcription_remote_data_source.dart';
import '../../features/audio/data/repositories/audio_repository_impl.dart';
import '../../features/audio/domain/repository/audio_repository.dart';
import '../../features/audio/domain/usecases/cancel_recording_usecase.dart';
import '../../features/audio/domain/usecases/start_recording_usecase.dart';
import '../../features/audio/domain/usecases/stop_recording_usecase.dart';
import '../../features/audio/domain/usecases/upload_audio_usecase.dart';
import '../../features/audio/domain/usecases/transcribe_audio_usecase.dart';
import '../../features/audio/presentation/cubit/audio_cubit.dart';
import 'core_locator.dart';

void setupAudioDependencies() {
  if (!getIt.isRegistered<http.Client>()) {
    getIt.registerLazySingleton<http.Client>(() => http.Client());
  }
  if (!getIt.isRegistered<AudioRecorder>()) {
    getIt.registerLazySingleton<AudioRecorder>(() => AudioRecorder());
  }
  if (!getIt.isRegistered<IAudioRemoteDataSource>()) {
    getIt.registerLazySingleton<IAudioRemoteDataSource>(
      () => AudioRemoteDataSourceImpl(
        getIt<AudioRecorder>(),
        auth: getIt<FirebaseAuth>(),
      ),
    );
  }
  if (!getIt.isRegistered<IAudioTranscriptionRemoteDataSource>()) {
    getIt.registerLazySingleton<IAudioTranscriptionRemoteDataSource>(
      () => AudioTranscriptionRemoteDataSourceImpl(
        auth: getIt<FirebaseAuth>(),
        client: getIt<http.Client>(),
        baseUrl: const String.fromEnvironment('AUDIO_TRANSCRIPTION_API_URL'),
      ),
    );
  }
  if (!getIt.isRegistered<IAudioRepository>()) {
    getIt.registerLazySingleton<IAudioRepository>(
      () => AudioRepositoryImpl(
        getIt<IAudioRemoteDataSource>(),
        getIt<IAudioTranscriptionRemoteDataSource>(),
      ),
    );
  }
  if (!getIt.isRegistered<StartRecordingUseCase>()) {
    getIt.registerFactory(
      () => StartRecordingUseCase(getIt<IAudioRepository>()),
    );
    getIt.registerFactory(
      () => StopRecordingUseCase(getIt<IAudioRepository>()),
    );
    getIt.registerFactory(
      () => CancelRecordingUseCase(getIt<IAudioRepository>()),
    );
    getIt.registerFactory(() => UploadAudioUseCase(getIt<IAudioRepository>()));
    getIt.registerFactory(
      () => TranscribeAudioUseCase(getIt<IAudioRepository>()),
    );
    getIt.registerFactory(
      () => AudioCubit(
        getIt<StartRecordingUseCase>(),
        getIt<StopRecordingUseCase>(),
        getIt<CancelRecordingUseCase>(),
        getIt<UploadAudioUseCase>(),
        getIt<TranscribeAudioUseCase>(),
      ),
    );
  }
}
