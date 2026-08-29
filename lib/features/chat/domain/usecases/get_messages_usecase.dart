import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/chat_message.dart';
import '../repositories/i_chat_repository.dart';

class GetMessagesUseCase {
  final IChatRepository repository;

  GetMessagesUseCase(this.repository);

  Stream<Either<Failure, List<ChatMessage>>> call(
    String chatId, {
    int limit = 30,
  }) {
    if (chatId.isEmpty) {
      return Stream.value(Left(ServerFailure('معرف المحادثة غير صالح')));
    }

    return repository.getMessages(chatId, limit: limit);
  }
}
