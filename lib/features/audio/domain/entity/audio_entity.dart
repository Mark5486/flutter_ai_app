import 'package:equatable/equatable.dart';

enum AudioType { audio }

class AudioEntity extends Equatable {
  const AudioEntity({
    required this.id,
    required this.sizeBytes,
    required this.type,
    required this.url,
  });

  final String id;
  final int sizeBytes;
  final AudioType type;
  final String url;

  @override
  List<Object?> get props => [id, sizeBytes, type, url];
}
