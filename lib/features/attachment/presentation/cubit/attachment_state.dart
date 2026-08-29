import 'package:equatable/equatable.dart';

import '../../domain/entity/attachment_entity.dart';

abstract class AttachmentState extends Equatable {
  const AttachmentState();

  @override
  List<Object?> get props => [];
}

class AttachmentIdle extends AttachmentState {}

class AttachmentPicking extends AttachmentState {}

class AttachmentReady extends AttachmentState {
  const AttachmentReady(this.attachment);

  final AttachmentEntity attachment;

  @override
  List<Object?> get props => [attachment];
}

class AttachmentUploading extends AttachmentState {
  const AttachmentUploading(this.attachment);

  final AttachmentEntity attachment;

  @override
  List<Object?> get props => [attachment];
}

class AttachmentFailure extends AttachmentState {
  const AttachmentFailure(this.message, {this.previousAttachment});

  final String message;
  final AttachmentEntity? previousAttachment;

  @override
  List<Object?> get props => [message, previousAttachment];
}
