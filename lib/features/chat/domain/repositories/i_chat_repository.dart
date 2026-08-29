import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../attachment/domain/entity/attachment_entity.dart';
import '../entities/chat_message.dart';

abstract class IChatRepository {
  Stream<Either<Failure, List<Map<String, dynamic>>>> getChatSessions();

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
  });

  Future<Either<Failure, void>> retryMessage(String chatId, String messageId);

  Future<Either<Failure, void>> deleteMessage(String chatId, String messageId);

  Future<Either<Failure, void>> deleteChatSession(String chatId);
}
