import 'dart:typed_data';

import 'package:equatable/equatable.dart';

enum AttachmentType { image }

class AttachmentEntity extends Equatable {
  const AttachmentEntity({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.sizeBytes,
    required this.type,
    required this.bytes,
  });

  final String id;
  final String name;
  final String mimeType;
  final int sizeBytes;
  final AttachmentType type;

  final Uint8List bytes;

  @override
  List<Object?> get props => [id, name, mimeType, sizeBytes, type, bytes];
}
