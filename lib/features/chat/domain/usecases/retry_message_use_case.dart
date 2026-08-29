import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/i_chat_repository.dart';

class RetryMessageUseCase {
  const RetryMessageUseCase(this._repository);

  final IChatRepository _repository;

  Future<Either<Failure, void>> call({
    required String chatId,
    required String messageId,
  }) {
    if (chatId.trim().isEmpty || messageId.trim().isEmpty) {
      return Future.value(
        Left(ServerFailure('بيانات إعادة المحاولة غير صالحة')),
      );
    }

    return _repository.retryMessage(chatId, messageId);
  }
}
