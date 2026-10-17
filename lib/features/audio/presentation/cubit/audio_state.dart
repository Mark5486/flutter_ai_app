import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../domain/entity/audio_entity.dart';

abstract class AudioState extends Equatable {
  const AudioState();

  @override
  List<Object?> get props => [];
}

class AudioIdle extends AudioState {}

class AudioRecording extends AudioState {}

class AudioRecorded extends AudioState {
  const AudioRecorded(this.bytes);

  final Uint8List bytes;

  @override
  List<Object?> get props => [bytes];
}

class AudioUploading extends AudioState {
  const AudioUploading(this.bytes);

  final Uint8List bytes;

  @override
  List<Object?> get props => [bytes];
}

class AudioReady extends AudioState {
  const AudioReady(this.audio);

  final AudioEntity audio;

  @override
  List<Object?> get props => [audio];
}

class AudioFailure extends AudioState {
  const AudioFailure(this.message, {this.bytes, this.previousAudio});

  final String message;
  final Uint8List? bytes;
  final AudioEntity? previousAudio;

  @override
  List<Object?> get props => [message, bytes, previousAudio];
}
