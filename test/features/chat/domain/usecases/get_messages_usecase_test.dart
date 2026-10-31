import 'package:dartz/dartz.dart';
import 'package:flutter_ai_app/features/chat/domain/usecases/get_messages_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_chat_repository.dart';

void main() {
  late MockChatRepository repository;
  late GetMessagesUseCase useCase;

  setUpAll(registerChatTestFallbacks);

  setUp(() {
    repository = MockChatRepository();
    useCase = GetMessagesUseCase(repository);
  });

  group('GetMessagesUseCase', () {
    test('returns a failure stream for an empty chat id without touching the repository', () async {
      final events = await useCase('').toList();

      expect(events, hasLength(1));
      expect(events.first.isLeft(), isTrue);
      expect(events.first.fold((failure) => failure.message, (_) => ''), 'معرف المحادثة غير صالح');
      verifyNever(() => repository.getMessages(any(), limit: any(named: 'limit')));
    });

    test('streams the repository live messages for a valid chat', () async {
      final messages = [fakeChatMessage(id: 'm1', text: 'أول رسالة')];
      when(() => repository.getMessages('chat-1', limit: 30))
          .thenAnswer((_) => Stream.value(Right(messages)));

      final events = await useCase('chat-1').toList();

      expect(events, hasLength(1));
      expect(events.first.getOrElse(() => const []), messages);
      verify(() => repository.getMessages('chat-1', limit: 30)).called(1);
    });
  });
}
