// attachment/domain/errors/attachment_failure.dart
import 'package:equatable/equatable.dart';

abstract class AttachmentFailure extends Equatable {
  const AttachmentFailure();

  @override
  List<Object?> get props => [];
}

class AttachmentPickFailure extends AttachmentFailure {
  final String message;
  const AttachmentPickFailure(this.message);
  @override
  List<Object?> get props => [message];
}

class AttachmentSizeExceededFailure extends AttachmentFailure {
  final int maxSize;
  final int actualSize;
  const AttachmentSizeExceededFailure({
    required this.maxSize,
    required this.actualSize,
  });
  @override
  List<Object?> get props => [maxSize, actualSize];
}

class AttachmentTypeNotSupportedFailure extends AttachmentFailure {
  final String type;
  const AttachmentTypeNotSupportedFailure(this.type);
  @override
  List<Object?> get props => [type];
}

class AttachmentUploadFailure extends AttachmentFailure {
  final String message;
  const AttachmentUploadFailure(this.message);
  @override
  List<Object?> get props => [message];
}
