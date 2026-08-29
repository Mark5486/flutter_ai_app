import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/i_chat_repository.dart';

class DeleteMessageUseCase {
  final IChatRepository repository;

  DeleteMessageUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String chatId,
    required String messageId,
  }) async {
    if (chatId.isEmpty || messageId.isEmpty) {
      return Left(ServerFailure('بيانات الحذف غير صالحة'));
    }
    return await repository.deleteMessage(chatId, messageId);
  }
}
