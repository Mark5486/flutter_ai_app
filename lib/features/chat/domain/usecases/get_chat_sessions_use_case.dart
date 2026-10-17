import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/chat_session.dart';
import '../repositories/i_chat_repository.dart';

class GetChatSessionsUseCase {
  final IChatRepository repository;

  GetChatSessionsUseCase(this.repository);

  Stream<Either<Failure, List<ChatSession>>> call() {
    return repository.getChatSessions();
  }
}
