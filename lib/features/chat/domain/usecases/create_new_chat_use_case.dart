import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/i_chat_repository.dart';

class CreateNewChatUseCase {
  final IChatRepository repository;

  CreateNewChatUseCase(this.repository);

  Future<Either<Failure, String>> call() async {
    return await repository.createNewChat();
  }
}
