import 'package:flutter_ai_app/features/chat/domain/entities/chat_message.dart';
import 'package:flutter_ai_app/features/chat/domain/entities/message_source.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.text,
    required super.sender,
    required super.timestamp,
    super.status,
    super.imageUrl,
    super.imageMimeType,
    super.audioUrl,
    super.thoughts,
    super.sources,
    super.isEdited,
    super.originalText,
    super.editedAt,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return ChatMessageModel(
      id: docId ?? (map['id'] as String? ?? ''),
      text: map['text'] as String? ?? '',
      sender: _senderFromMap(map),
      status: _statusFromMap(map['status']),
      imageUrl: map['imageUrl'] as String?,
      imageMimeType: map['imageMimeType'] as String?,
      audioUrl: map['audioUrl'] as String?,
      thoughts: map['thoughts'] as String?,
      sources: _sourcesFromMap(map['sources']),
      isEdited: map['isEdited'] == true,
      originalText: map['originalText'] as String?,
      editedAt: map['editedAt'] != null
          ? (map['editedAt'] as dynamic).toDate() as DateTime
          : null,
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

  static List<MessageSource> _sourcesFromMap(dynamic value) {
    if (value is! List) return const [];

    final sources = <MessageSource>[];

    for (final item in value) {
      if (item is Map<String, dynamic> &&
          item['title'] is String &&
          item['url'] is String &&
          (item['title'] as String).trim().isNotEmpty &&
          (item['url'] as String).trim().isNotEmpty) {
        sources.add(
          MessageSource(
            title: item['title'] as String,
            url: item['url'] as String,
          ),
        );
      }
    }

    return List.unmodifiable(sources);
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderId': sender == MessageSender.user ? 'user' : 'ai',
      'status': _statusToString(status),
      'timestamp': timestamp,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (imageMimeType != null) 'imageMimeType': imageMimeType,
      if (audioUrl != null) 'audioUrl': audioUrl,
      if (thoughts != null) 'thoughts': thoughts,
      if (sources.isNotEmpty)
        'sources': sources.map((source) => source.toMap()).toList(),
      if (isEdited) 'isEdited': true,
      if (originalText != null) 'originalText': originalText,
      if (editedAt != null) 'editedAt': editedAt,
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
      audioUrl: audioUrl,
      thoughts: thoughts,
      sources: sources,
      isEdited: isEdited,
      originalText: originalText,
      editedAt: editedAt,
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
