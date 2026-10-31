import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_ai_app/features/audio/data/models/audio_models.dart';
import 'package:flutter_ai_app/features/audio/domain/entity/audio_entity.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'audio_recording_file_reader_stub.dart'
    if (dart.library.io) 'audio_recording_file_reader_io.dart'
    if (dart.library.html) 'audio_recording_file_reader_web.dart'
    as recording_file_reader;

abstract class IAudioRemoteDataSource {
  Future<void> startRecording();

  Future<Uint8List> stopRecording();

  Future<void> cancelRecording();

  Future<AudioModel> uploadAudio(Uint8List bytes);
}

class AudioRemoteDataSourceImpl implements IAudioRemoteDataSource {
  AudioRemoteDataSourceImpl(
    this._audioRecorder, {
    FirebaseAuth? auth,
  }) : _auth = auth ?? FirebaseAuth.instance;

  static const int _maxStorableBytes = 600 * 1024;

  final AudioRecorder _audioRecorder;
  final FirebaseAuth _auth;

  String? _recordingPath;
  String _recordingMimeType = 'audio/mp4';
  String _recordingExtension = 'm4a';

  @override
  Future<void> startRecording() async {
    if (_recordingPath != null) {
      throw StateError('يوجد تسجيل قيد التشغيل بالفعل.');
    }

    final hasPermission = await _audioRecorder.hasPermission();

    if (!hasPermission) {
      throw Exception('Microphone permission denied');
    }

    final encoder = kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc;
    _recordingMimeType = kIsWeb ? 'audio/webm' : 'audio/mp4';
    _recordingExtension = kIsWeb ? 'webm' : 'm4a';
    final fileName =
        'audio_${DateTime.now().microsecondsSinceEpoch}.$_recordingExtension';
    final path =
        kIsWeb ? fileName : '${(await getTemporaryDirectory()).path}/$fileName';
    _recordingPath = path;

    try {

      await _audioRecorder.start(
        RecordConfig(
          encoder: encoder,
          bitRate: 48000,
          sampleRate: 22050,
          numChannels: 1,
        ),
        path: path,
      );
    } catch (_) {
      _recordingPath = null;
      rethrow;
    }
  }

  @override
  Future<Uint8List> stopRecording() async {
    if (_recordingPath == null) {
      throw StateError('لا يوجد تسجيل لإيقافه.');
    }

    final path = await _audioRecorder.stop();

    if (path == null) {
      _recordingPath = null;
      throw Exception('Recording could not be stopped');
    }

    _recordingPath = null;
    final bytes = await recording_file_reader.readRecordingBytes(
      path,
      httpClient: http.Client(),
    );
    if (bytes.length > 20 * 1024 * 1024) {
      throw StateError('حجم التسجيل أكبر من الحد المسموح (20 ميجابايت).');
    }
    return bytes;
  }

  @override
  Future<void> cancelRecording() async {
    final path = _recordingPath;
    if (path == null) return;

    await _audioRecorder.cancel();

    _recordingPath = null;
  }

  @override
  Future<AudioModel> uploadAudio(Uint8List bytes) async {
    if (bytes.isEmpty) throw ArgumentError('لا يمكن رفع تسجيل فارغ.');
    if (bytes.length > _maxStorableBytes) {
      throw StateError(
        'التسجيل أطول من الحد المسموح (حوالي دقيقة ونصف). '
        'سجّل رسالة صوتية أقصر.',
      );
    }

    final user = _auth.currentUser;
    if (user == null) throw StateError('يجب تسجيل الدخول لرفع التسجيل.');

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final dataUrl = 'data:$_recordingMimeType;base64,${base64Encode(bytes)}';

    return AudioModel(
      id: id,
      sizeBytes: bytes.length,
      type: AudioType.audio,
      url: dataUrl,
    );
  }
}
