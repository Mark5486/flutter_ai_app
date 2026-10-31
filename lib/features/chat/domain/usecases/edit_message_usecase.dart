import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/i_chat_repository.dart';

class EditMessageUseCase {
  final IChatRepository repository;

  EditMessageUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String chatId,
    required String messageId,
    required String newText,
  }) async {
    if (chatId.isEmpty || messageId.isEmpty) {
      return Left(ServerFailure('بيانات التعديل غير صالحة'));
    }

    final text = newText.trim();

    if (text.isEmpty) {
      return Left(ServerFailure('لا يمكن حفظ رسالة فارغة'));
    }

    if (text.length > 6000) {
      return Left(ServerFailure('الرسالة طويلة جدًا. الحد الأقصى 6000 حرف.'));
    }

    return await repository.editMessage(
      chatId,
      messageId,
      text,
    );
  }
}
