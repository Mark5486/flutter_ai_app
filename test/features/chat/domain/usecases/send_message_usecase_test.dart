import 'package:dartz/dartz.dart';
import 'package:flutter_ai_app/core/errors/failures.dart';
import 'package:flutter_ai_app/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_chat_repository.dart';

void main() {
  late MockChatRepository repository;
  late SendMessageUseCase useCase;

  setUp(() {
    repository = MockChatRepository();
    useCase = SendMessageUseCase(repository);
  });

  group('SendMessageUseCase', () {
    test('rejects an empty chat id', () async {
      final result = await useCase(chatId: '', text: 'ازيك');

      expect(result.isLeft(), isTrue);
      expect(result.fold((failure) => failure.message, (_) => ''), 'معرف المحادثة غير صالح');
      verifyNever(() => repository.sendMessage(any(), any(),
          attachment: null, audio: null, webSearch: false, thinking: false));
    });

    test('rejects an empty message with no attachment and no audio', () async {
      final result = await useCase(chatId: 'chat-1', text: '   ');

      expect(result.isLeft(), isTrue);
      expect(result.fold((failure) => failure.message, (_) => ''), 'لا يمكن إرسال رسالة فارغة');
      verifyNever(() => repository.sendMessage(any(), any(),
          attachment: null, audio: null, webSearch: false, thinking: false));
    });

    test('trims text and passes the web search flag to the repository', () async {
      when(() => repository.sendMessage('chat-1', 'ازيك يا معلم',
              attachment: null, audio: null, webSearch: true, thinking: false))
          .thenAnswer((_) async => const Right(null));

      final result = await useCase(
        chatId: 'chat-1',
        text: '  ازيك يا معلم  ',
        webSearch: true,
      );

      expect(result.isRight(), isTrue);
      verify(() => repository.sendMessage('chat-1', 'ازيك يا معلم',
          attachment: null, audio: null, webSearch: true, thinking: false)).called(1);
    });

    test('passes the thinking flag to the repository', () async {
      when(() => repository.sendMessage('chat-1', 'سؤال صعب',
              attachment: null, audio: null, webSearch: false, thinking: true))
          .thenAnswer((_) async => const Right(null));

      final result = await useCase(
        chatId: 'chat-1',
        text: 'سؤال صعب',
        thinking: true,
      );

      expect(result.isRight(), isTrue);
      verify(() => repository.sendMessage('chat-1', 'سؤال صعب',
          attachment: null, audio: null, webSearch: false, thinking: true)).called(1);
    });

    test('disables web search and thinking when both flags are omitted', () async {
      when(() => repository.sendMessage('chat-1', 'مرحبا',
              attachment: null, audio: null, webSearch: false, thinking: false))
          .thenAnswer((_) async => const Right(null));

      await useCase(chatId: 'chat-1', text: 'مرحبا');

      verify(() => repository.sendMessage('chat-1', 'مرحبا',
          attachment: null, audio: null, webSearch: false, thinking: false)).called(1);
    });

    test('surfaces the repository failure as-is', () async {
      when(() => repository.sendMessage('chat-1', 'مرحبا',
              attachment: null, audio: null, webSearch: false, thinking: false))
          .thenAnswer((_) async => const Left(ServerFailure('مفيش اتصال')));

      final result = await useCase(chatId: 'chat-1', text: 'مرحبا');

      expect(result.fold((failure) => failure.message, (_) => ''), 'مفيش اتصال');
    });
  });
}
