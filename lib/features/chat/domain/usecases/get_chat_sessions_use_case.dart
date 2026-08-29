import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/i_chat_repository.dart';

class GetChatSessionsUseCase {
  final IChatRepository repository;

  GetChatSessionsUseCase(this.repository);

  Stream<Either<Failure, List<Map<String, dynamic>>>> call() {
    return repository.getChatSessions();
  }
}
