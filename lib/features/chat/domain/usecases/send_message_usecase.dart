import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../attachment/domain/entity/attachment_entity.dart';
import '../repositories/i_chat_repository.dart';

class SendMessageUseCase {
  final IChatRepository repository;

  SendMessageUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String chatId,
    required String text,
    AttachmentEntity? attachment,
  }) async {
    if (chatId.isEmpty) {
      return Left(ServerFailure('معرف المحادثة غير صالح'));
    }

    if (text.trim().isEmpty && attachment == null) {
      return Left(ServerFailure('لا يمكن إرسال رسالة فارغة'));
    }

    return await repository.sendMessage(
      chatId,
      text.trim(),
      attachment: attachment,
    );
  }
}
