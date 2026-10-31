import 'package:equatable/equatable.dart';

import 'message_source.dart';

enum MessageSender { user, ai }

enum MessageStatus { sending, sent, failed }

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,

    required this.text,

    required this.sender,

    required this.timestamp,

    this.status = MessageStatus.sent,

    this.imageUrl,

    this.imageMimeType,

    this.audioUrl,

    this.thoughts,

    this.sources = const [],

    this.isEdited = false,

    this.originalText,

    this.editedAt,
  });

  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final MessageStatus status;
  final String? imageUrl;
  final String? imageMimeType;
  final String? audioUrl;

  final String? thoughts;

  final List<MessageSource> sources;

  final bool isEdited;

  
  final String? originalText;

  final DateTime? editedAt;

  bool get isSending => status == MessageStatus.sending;

  bool get isFailed => status == MessageStatus.failed;

  bool get hasImage => imageUrl != null;

  bool get hasAudio => audioUrl != null;

  bool get hasThoughts => thoughts != null && thoughts!.trim().isNotEmpty;

  bool get hasSources => sources.isNotEmpty;

  bool get canBeEdited =>
      sender == MessageSender.user && text.trim().isNotEmpty && !isSending;

  bool get hasOriginalText =>
      isEdited && originalText != null && originalText!.trim().isNotEmpty;

  @override
  List<Object?> get props => [
    id,

    text,

    sender,

    timestamp,

    status,

    imageUrl,

    imageMimeType,

    audioUrl,

    thoughts,

    sources,

    isEdited,

    originalText,

    editedAt,
  ];
}
