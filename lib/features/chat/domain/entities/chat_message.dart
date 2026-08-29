import 'package:equatable/equatable.dart';

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
  });

  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final MessageStatus status;

  final String? imageUrl;
  final String? imageMimeType;

  bool get isSending => status == MessageStatus.sending;
  bool get isFailed => status == MessageStatus.failed;
  bool get hasImage => imageUrl != null;

  @override
  List<Object?> get props => [
    id,
    text,
    sender,
    timestamp,
    status,
    imageUrl,
    imageMimeType,
  ];
}
