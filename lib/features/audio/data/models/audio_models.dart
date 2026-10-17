import '../../domain/entity/audio_entity.dart';

class AudioModel extends AudioEntity {
  const AudioModel({
    required super.id,
    required super.sizeBytes,
    required super.type,
    required super.url,
  });

  factory AudioModel.fromMap(Map<String, dynamic> map) {
    final id = map['id'];
    final sizeBytes = map['sizeBytes'];
    final type = map['type'];
    final url = map['url'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('Invalid audio id');
    }

    if (sizeBytes is! int || sizeBytes < 0) {
      throw const FormatException('Invalid audio size');
    }

    if (url is! String || url.isEmpty) {
      throw const FormatException('Invalid audio url');
    }

    final audioType = _audioTypeFromString(type);

    return AudioModel(id: id, sizeBytes: sizeBytes, type: audioType, url: url);
  }

  static AudioType _audioTypeFromString(Object? value) {
    switch (value) {
      case 'audio':
        return AudioType.audio;
      default:
        throw FormatException('Unsupported audio type: $value');
    }
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'sizeBytes': sizeBytes, 'type': type.name, 'url': url};
  }

  AudioEntity toEntity() {
    return AudioEntity(id: id, sizeBytes: sizeBytes, type: type, url: url);
  }
}
