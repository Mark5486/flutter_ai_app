import 'package:dartz/dartz.dart';
import 'package:flutter_ai_app/features/chat/domain/entities/chat_message.dart';
import 'package:flutter_ai_app/features/chat/domain/usecases/load_older_messages.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_chat_repository.dart';

void main() {
  late MockChatRepository repository;
  late LoadOlderMessagesUseCase useCase;

  setUpAll(registerChatTestFallbacks);

  setUp(() {
    repository = MockChatRepository();
    useCase = LoadOlderMessagesUseCase(repository);
  });

  group('LoadOlderMessagesUseCase', () {
    test('delegates the anchor message timestamp and id to the repository', () async {
      final beforeMessage = fakeChatMessage(id: 'm5', timestamp: DateTime(2024, 3, 3, 15, 30));
      final olderMessages = [
        fakeChatMessage(id: 'old-1', timestamp: DateTime(2024, 3, 3, 15, 0)),
      ];

      when(() => repository.loadOlderMessages(
            'chat-1',
            beforeTimestamp: DateTime(2024, 3, 3, 15, 30),
            beforeMessageId: 'm5',
            limit: 30,
          )).thenAnswer((_) async => Right(olderMessages));

      final result = await useCase(
        chatId: 'chat-1',
        beforeMessage: beforeMessage,
      );

      expect(result.getOrElse(() => const []), olderMessages);
      verify(() => repository.loadOlderMessages(
            'chat-1',
            beforeTimestamp: DateTime(2024, 3, 3, 15, 30),
            beforeMessageId: 'm5',
            limit: 30,
          )).called(1);
    });

    test('passes a custom page size through untouched', () async {
      final beforeMessage = fakeChatMessage(id: 'm5', timestamp: DateTime(2024, 3, 3, 15, 30));

      when(() => repository.loadOlderMessages(
            'chat-1',
            beforeTimestamp: DateTime(2024, 3, 3, 15, 30),
            beforeMessageId: 'm5',
            limit: 10,
          )).thenAnswer((_) async => const Right(<ChatMessage>[]));

      await useCase(chatId: 'chat-1', beforeMessage: beforeMessage, limit: 10);

      verify(() => repository.loadOlderMessages(
            'chat-1',
            beforeTimestamp: DateTime(2024, 3, 3, 15, 30),
            beforeMessageId: 'm5',
            limit: 10,
          )).called(1);
    });
  });
}
