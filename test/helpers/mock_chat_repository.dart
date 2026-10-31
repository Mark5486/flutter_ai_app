import 'package:flutter_ai_app/features/chat/domain/entities/chat_message.dart';
import 'package:flutter_ai_app/features/chat/domain/entities/message_source.dart';
import 'package:flutter_ai_app/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockChatRepository extends Mock implements IChatRepository {}

ChatMessage fakeChatMessage({
  String id = 'msg-1',
  String text = 'محتوى تجريبي',
  MessageSender sender = MessageSender.user,
  DateTime? timestamp,
  MessageStatus status = MessageStatus.sent,
  String? thoughts,
  List<MessageSource> sources = const [],
  bool isEdited = false,
  String? originalText,
  DateTime? editedAt,
}) {
  return ChatMessage(
    id: id,
    text: text,
    sender: sender,
    timestamp: timestamp ?? DateTime(2024, 5, 1, 10),
    status: status,
    thoughts: thoughts,
    sources: sources,
    isEdited: isEdited,
    originalText: originalText,
    editedAt: editedAt,
  );
}

void registerChatTestFallbacks() {
  registerFallbackValue(DateTime(2024));
}
