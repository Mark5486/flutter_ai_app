import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/chat_message.dart';
import '../repositories/i_chat_repository.dart';

class LoadOlderMessagesUseCase {
  const LoadOlderMessagesUseCase(this._repository);

  final IChatRepository _repository;

  Future<Either<Failure, List<ChatMessage>>> call({
    required String chatId,
    required ChatMessage beforeMessage,
    int limit = 30,
  }) {
    return _repository.loadOlderMessages(
      chatId,
      beforeTimestamp: beforeMessage.timestamp,
      beforeMessageId: beforeMessage.id,
      limit: limit,
    );
  }
}
