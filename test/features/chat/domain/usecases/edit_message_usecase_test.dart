import 'package:dartz/dartz.dart';
import 'package:flutter_ai_app/core/errors/failures.dart';
import 'package:flutter_ai_app/features/chat/domain/usecases/edit_message_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_chat_repository.dart';

void main() {
  late MockChatRepository repository;
  late EditMessageUseCase useCase;

  setUp(() {
    repository = MockChatRepository();
    useCase = EditMessageUseCase(repository);
  });

  group('EditMessageUseCase', () {
    test('rejects an empty chat id', () async {
      final result = await useCase(chatId: '', messageId: 'msg-1', newText: 'نص');

      expect(result.isLeft(), isTrue);
      expect(result.fold((failure) => failure.message, (_) => ''), 'بيانات التعديل غير صالحة');
      verifyNever(() => repository.editMessage(any(), any(), any()));
    });

    test('rejects an empty message id', () async {
      final result = await useCase(chatId: 'chat-1', messageId: '', newText: 'نص');

      expect(result.isLeft(), isTrue);
      verifyNever(() => repository.editMessage(any(), any(), any()));
    });

    test('rejects an empty text', () async {
      final result = await useCase(chatId: 'chat-1', messageId: 'msg-1', newText: '   ');

      expect(result.isLeft(), isTrue);
      expect(result.fold((failure) => failure.message, (_) => ''), 'لا يمكن حفظ رسالة فارغة');
      verifyNever(() => repository.editMessage(any(), any(), any()));
    });

    test('rejects a text longer than 6000 characters', () async {
      final result = await useCase(chatId: 'chat-1', messageId: 'msg-1', newText: 'ا' * 6001);

      expect(result.isLeft(), isTrue);
      expect(
        result.fold((failure) => failure.message, (_) => ''),
        'الرسالة طويلة جدًا. الحد الأقصى 6000 حرف.',
      );
      verifyNever(() => repository.editMessage(any(), any(), any()));
    });

    test('trims the new text before saving', () async {
      when(() => repository.editMessage('chat-1', 'msg-1', 'النص الجديد'))
          .thenAnswer((_) async => const Right(null));

      final result = await useCase(
        chatId: 'chat-1',
        messageId: 'msg-1',
        newText: '  النص الجديد  ',
      );

      expect(result.isRight(), isTrue);
      verify(() => repository.editMessage('chat-1', 'msg-1', 'النص الجديد')).called(1);
    });

    test('surfaces the repository failure as-is', () async {
      when(() => repository.editMessage('chat-1', 'msg-1', 'نص'))
          .thenAnswer((_) async => const Left(ServerFailure('مرفوض')));

      final result = await useCase(chatId: 'chat-1', messageId: 'msg-1', newText: 'نص');

      expect(result.fold((failure) => failure.message, (_) => ''), 'مرفوض');
    });
  });
}
