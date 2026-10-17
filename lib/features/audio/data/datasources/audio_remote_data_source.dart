import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_ai_app/features/audio/data/models/audio_models.dart';
import 'package:flutter_ai_app/features/audio/domain/entity/audio_entity.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

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
    FirebaseStorage? storage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final AudioRecorder _audioRecorder;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  String? _recordingPath;

  @override
  Future<void> startRecording() async {
    if (_recordingPath != null) {
      throw StateError('يوجد تسجيل قيد التشغيل بالفعل.');
    }

    final hasPermission = await _audioRecorder.hasPermission();

    if (!hasPermission) {
      throw Exception('Microphone permission denied');
    }

    final directory = await getTemporaryDirectory();

    _recordingPath =
        '${directory.path}/audio_${DateTime.now().microsecondsSinceEpoch}.m4a';

    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _recordingPath!,
    );
  }

  @override
  Future<Uint8List> stopRecording() async {
    if (_recordingPath == null) {
      throw StateError('لا يوجد تسجيل لإيقافه.');
    }

    final path = await _audioRecorder.stop();

    if (path == null) {
      throw Exception('Recording could not be stopped');
    }

    final file = File(path);

    if (!await file.exists()) {
      throw Exception('Recording file not found');
    }

    if (await file.length() > 20 * 1024 * 1024) {
      await file.delete();
      _recordingPath = null;
      throw StateError('حجم التسجيل أكبر من الحد المسموح (20 ميجابايت).');
    }

    final bytes = await file.readAsBytes();

    await file.delete();

    _recordingPath = null;

    return bytes;
  }

  @override
  Future<void> cancelRecording() async {
    final path = _recordingPath;
    if (path == null) return;

    await _audioRecorder.cancel();

    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }

    _recordingPath = null;
  }

  @override
  Future<AudioModel> uploadAudio(Uint8List bytes) async {
    if (bytes.isEmpty) throw ArgumentError('لا يمكن رفع تسجيل فارغ.');
    if (bytes.length > 20 * 1024 * 1024) {
      throw ArgumentError('حجم التسجيل أكبر من الحد المسموح (20 ميجابايت).');
    }

    final user = _auth.currentUser;
    if (user == null) throw StateError('يجب تسجيل الدخول لرفع التسجيل.');

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final reference = _storage.ref().child('users/${user.uid}/audio/$id.m4a');
    final snapshot = await reference.putData(
      bytes,
      SettableMetadata(contentType: 'audio/mp4'),
    );

    return AudioModel(
      id: id,
      sizeBytes: bytes.length,
      type: AudioType.audio,
      url: await snapshot.ref.getDownloadURL(),
    );
  }
}
