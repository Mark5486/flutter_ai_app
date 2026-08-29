import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/i_chat_repository.dart';

class DeleteChatSessionUseCase {
  final IChatRepository repository;

  DeleteChatSessionUseCase(this.repository);

  Future<Either<Failure, void>> call(String chatId) async {
    if (chatId.isEmpty) {
      return Left(ServerFailure('معرف المحادثة غير صالح'));
    }
    return await repository.deleteChatSession(chatId);
  }
}
