import 'package:dartz/dartz.dart';
import 'package:flutter_ai_app/features/audio/domain/entity/audio_entity.dart';

import '../../../../core/errors/failures.dart';
import '../../../attachment/domain/entity/attachment_entity.dart';
import '../entities/chat_message.dart';
import '../entities/chat_session.dart';

abstract class IChatRepository {
  Stream<Either<Failure, List<ChatSession>>> getChatSessions();

  Future<Either<Failure, String>> createNewChat();

  Stream<Either<Failure, List<ChatMessage>>> getMessages(
    String chatId, {
    int limit,
  });

  Future<Either<Failure, List<ChatMessage>>> loadOlderMessages(
    String chatId, {
    required DateTime beforeTimestamp,
    required String beforeMessageId,
    int limit,
  });

  Future<Either<Failure, void>> sendMessage(
    String chatId,
    String text, {
    AttachmentEntity? attachment,
    AudioEntity? audio,
    bool webSearch,
    bool thinking,
  });

  Future<Either<Failure, void>> retryMessage(String chatId, String messageId);

  Future<Either<Failure, void>> editMessage(
    String chatId,
    String messageId,
    String newText,
  );

  Future<Either<Failure, void>> deleteChatSession(String chatId);
}
