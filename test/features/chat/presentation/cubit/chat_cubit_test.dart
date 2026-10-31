import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_ai_app/core/errors/failures.dart';
import 'package:flutter_ai_app/features/chat/domain/entities/chat_message.dart';
import 'package:flutter_ai_app/features/chat/domain/usecases/create_new_chat_use_case.dart';
import 'package:flutter_ai_app/features/chat/domain/usecases/get_messages_usecase.dart';
import 'package:flutter_ai_app/features/chat/domain/usecases/load_older_messages.dart';
import 'package:flutter_ai_app/features/chat/domain/usecases/retry_message_use_case.dart';
import 'package:flutter_ai_app/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:flutter_ai_app/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:flutter_ai_app/features/chat/presentation/cubit/chat_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_chat_repository.dart';

void main() {
  late MockChatRepository repository;

  setUpAll(registerChatTestFallbacks);

  setUp(() {
    repository = MockChatRepository();
  });

  ChatCubit buildCubit({String chatId = 'chat-1'}) {
    final cubit = ChatCubit(
      SendMessageUseCase(repository),
      GetMessagesUseCase(repository),
      CreateNewChatUseCase(repository),
      LoadOlderMessagesUseCase(repository),
      RetryMessageUseCase(repository),
      chatId: chatId,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  Future<void> flushEventQueue() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  group('ChatCubit', () {
    test('initChat with an empty chat id settles on an empty success state', () {
      final cubit = buildCubit(chatId: '');

      final state = cubit.state;
      expect(state, isA<ChatSuccess>());
      state as ChatSuccess;
      expect(state.messages, isEmpty);
      expect(state.chatId, '');
      expect(state.hasMore, isFalse);

      verifyNever(() => repository.getMessages(any(), limit: any(named: 'limit')));
    });

    test('sendMessage creates a new chat and trims the text before sending', () async {
      when(() => repository.createNewChat()).thenAnswer((_) async => const Right('chat-new-1'));
      when(() => repository.getMessages(any(), limit: any(named: 'limit')))
          .thenAnswer((_) => const Stream.empty());
      when(() => repository.sendMessage('chat-new-1', 'ازيك يا معلم',
              attachment: null, audio: null, webSearch: false, thinking: false))
          .thenAnswer((_) async => const Right(null));

      final cubit = buildCubit(chatId: '');

      await cubit.sendMessage('  ازيك يا معلم  ');

      expect(cubit.activeChatId, 'chat-new-1');
      verify(() => repository.createNewChat()).called(1);
      verify(() => repository.sendMessage('chat-new-1', 'ازيك يا معلم',
          attachment: null, audio: null, webSearch: false, thinking: false)).called(1);
    });

    test('sendMessage clears the sending flag and reflects streamed messages', () async {
      final message = fakeChatMessage(id: 'm1', timestamp: DateTime(2024, 5, 1, 10));
      when(() => repository.getMessages(any(), limit: any(named: 'limit')))
          .thenAnswer((_) => Stream.value(Right(<ChatMessage>[message])));
      when(() => repository.sendMessage('chat-1', 'اهلا',
              attachment: null, audio: null, webSearch: true, thinking: false))
          .thenAnswer((_) async => const Right(null));

      final cubit = buildCubit();
      await flushEventQueue();

      await cubit.sendMessage('اهلا', webSearch: true);

      final state = cubit.state;
      expect(state, isA<ChatSuccess>());
      state as ChatSuccess;
      expect(state.isSending, isFalse);
      expect(state.messages, hasLength(1));
      expect(state.messages.first.id, 'm1');
      expect(state.chatId, 'chat-1');
      expect(state.sendError, isNull);
    });

    test('sendMessage forwards the thinking flag to the repository', () async {
      when(() => repository.getMessages(any(), limit: any(named: 'limit')))
          .thenAnswer((_) => const Stream.empty());
      when(() => repository.sendMessage('chat-1', 'سؤال عميق',
              attachment: null, audio: null, webSearch: false, thinking: true))
          .thenAnswer((_) async => const Right(null));

      final cubit = buildCubit();
      await flushEventQueue();

      await cubit.sendMessage('سؤال عميق', thinking: true);

      verify(() => repository.sendMessage('chat-1', 'سؤال عميق',
          attachment: null, audio: null, webSearch: false, thinking: true)).called(1);
    });

    test('sendMessage surfaces the failure message as sendError', () async {
      when(() => repository.getMessages(any(), limit: any(named: 'limit')))
          .thenAnswer((_) => Stream.value(const Right(<ChatMessage>[])));
      when(() => repository.sendMessage('chat-1', 'اهلا',
              attachment: null, audio: null, webSearch: false, thinking: false))
          .thenAnswer((_) async => const Left(ServerFailure('السيرفر مش متاح')));

      final cubit = buildCubit();
      await flushEventQueue();

      await cubit.sendMessage('اهلا');

      final state = cubit.state;
      expect(state, isA<ChatSuccess>());
      state as ChatSuccess;
      expect(state.sendError, 'السيرفر مش متاح');
      expect(state.isSending, isFalse);
    });

    test('sendMessage ignores an empty message without touching the repository', () async {
      when(() => repository.getMessages(any(), limit: any(named: 'limit')))
          .thenAnswer((_) => const Stream.empty());

      final cubit = buildCubit();

      await cubit.sendMessage('   ');

      verifyNever(() => repository.sendMessage(any(), any(),
          attachment: null, audio: null, webSearch: false, thinking: false));
    });

    test('the live messages stream merges, dedupes and keeps newest-first order', () async {
      final controller = StreamController<Either<Failure, List<ChatMessage>>>();
      addTearDown(controller.close);

      when(() => repository.getMessages(any(), limit: any(named: 'limit')))
          .thenAnswer((_) => controller.stream);

      final m1 = fakeChatMessage(id: 'm1', timestamp: DateTime(2024, 5, 1, 10));
      final m2OldVersion = fakeChatMessage(
        id: 'm2',
        text: 'النسخة القديمة',
        timestamp: DateTime(2024, 5, 1, 11),
      );
      final m2NewVersion = fakeChatMessage(
        id: 'm2',
        text: 'النسخة الجديدة بعد التعديل',
        timestamp: DateTime(2024, 5, 1, 11),
      );
      final m3 = fakeChatMessage(id: 'm3', timestamp: DateTime(2024, 5, 1, 12));

      final cubit = buildCubit();

      controller.add(Right(<ChatMessage>[m1, m2OldVersion]));
      await flushEventQueue();

      var state = cubit.state as ChatSuccess;
      expect(state.messages.map((message) => message.id), ['m2', 'm1']);

      controller.add(Right(<ChatMessage>[m2NewVersion, m3]));
      await flushEventQueue();

      state = cubit.state as ChatSuccess;
      expect(state.messages.map((message) => message.id), ['m3', 'm2', 'm1']);
      expect(
        state.messages.firstWhere((message) => message.id == 'm2').text,
        'النسخة الجديدة بعد التعديل',
      );
    });

    test('loadMoreMessages is ignored while there is no more history', () async {
      when(() => repository.getMessages(any(), limit: any(named: 'limit'))).thenAnswer(
          (_) => Stream.value(Right([fakeChatMessage(id: 'm1', timestamp: DateTime(2024, 5, 1))])));

      final cubit = buildCubit();
      await flushEventQueue();

      await cubit.loadMoreMessages();

      verifyNever(() => repository.loadOlderMessages(any(),
          beforeTimestamp: any(named: 'beforeTimestamp'),
          beforeMessageId: any(named: 'beforeMessageId'),
          limit: any(named: 'limit')));
    });

    test('loadMoreMessages appends the older page and stops when it comes back short', () async {
      final anchor = DateTime(2024, 5, 2, 12);
      final recentPage = List.generate(
        30,
        (index) => fakeChatMessage(
          id: 'r$index',
          timestamp: anchor.subtract(Duration(minutes: index)),
        ),
      );
      final olderMessage = fakeChatMessage(id: 'old-1', timestamp: DateTime(2024, 4, 1, 9));

      when(() => repository.getMessages(any(), limit: any(named: 'limit')))
          .thenAnswer((_) => Stream.value(Right(recentPage)));
      when(() => repository.loadOlderMessages(
            'chat-1',
            beforeTimestamp: anchor.subtract(const Duration(minutes: 29)),
            beforeMessageId: 'r29',
            limit: 30,
          )).thenAnswer((_) async => Right(<ChatMessage>[olderMessage]));

      final cubit = buildCubit();
      await flushEventQueue();

      await cubit.loadMoreMessages();

      final state = cubit.state as ChatSuccess;
      expect(state.messages, hasLength(31));
      expect(state.messages.last.id, 'old-1');
      expect(state.hasMore, isFalse);
      expect(state.isLoadingMore, isFalse);
    });

    test('retryMessage delegates to the repository for the active chat', () async {
      when(() => repository.getMessages(any(), limit: any(named: 'limit')))
          .thenAnswer((_) => const Stream.empty());
      when(() => repository.retryMessage('chat-1', 'msg-9'))
          .thenAnswer((_) async => const Right(null));

      final cubit = buildCubit();

      await cubit.retryMessage('msg-9');

      verify(() => repository.retryMessage('chat-1', 'msg-9')).called(1);
    });
  });
}
