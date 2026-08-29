import 'package:flutter_ai_app/features/chat/domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.text,
    required super.sender,
    required super.timestamp,
    super.status,
    super.imageUrl,
    super.imageMimeType,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return ChatMessageModel(
      id: docId ?? (map['id'] as String? ?? ''),
      text: map['text'] as String? ?? '',
      sender: _senderFromMap(map),
      status: _statusFromMap(map['status']),
      imageUrl: map['imageUrl'] as String?,
      imageMimeType: map['imageMimeType'] as String?,
      timestamp:
          map['timestamp'] != null
              ? (map['timestamp'] as dynamic).toDate() as DateTime
              : DateTime.now(),
    );
  }

  static MessageSender _senderFromMap(Map<String, dynamic> map) {
    final sender = map['senderId'] ?? map['sender'];

    return sender == 'user' ? MessageSender.user : MessageSender.ai;
  }

  static MessageStatus _statusFromMap(dynamic value) {
    switch (value) {
      case 'sending':
        return MessageStatus.sending;
      case 'failed':
        return MessageStatus.failed;
      case 'sent':
      default:
        return MessageStatus.sent;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderId': sender == MessageSender.user ? 'user' : 'ai',
      'status': _statusToString(status),
      'timestamp': timestamp,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (imageMimeType != null) 'imageMimeType': imageMimeType,
    };
  }

  ChatMessage toEntity() {
    return ChatMessage(
      id: id,
      text: text,
      sender: sender,
      status: status,
      timestamp: timestamp,
      imageUrl: imageUrl,
      imageMimeType: imageMimeType,
    );
  }

  static String _statusToString(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return 'sending';
      case MessageStatus.failed:
        return 'failed';
      case MessageStatus.sent:
        return 'sent';
    }
  }
}
