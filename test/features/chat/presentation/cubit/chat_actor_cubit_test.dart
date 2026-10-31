import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_ai_app/core/errors/failures.dart';
import 'package:flutter_ai_app/features/chat/domain/usecases/edit_message_usecase.dart';
import 'package:flutter_ai_app/features/chat/presentation/cubit/chat_actor_cubit.dart';
import 'package:flutter_ai_app/features/chat/presentation/cubit/chat_actor_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_chat_repository.dart';

void main() {
  late MockChatRepository repository;

  setUp(() {
    repository = MockChatRepository();
  });

  ChatActorCubit buildCubit() {
    final cubit = ChatActorCubit(
      EditMessageUseCase(repository),
    );
    addTearDown(cubit.close);
    return cubit;
  }

  group('ChatActorCubit', () {
    group('editMessage', () {
      blocTest<ChatActorCubit, ChatActorState>(
        'emits [Loading, EditSuccess] when the edit succeeds',
        setUp: () {
          when(() => repository.editMessage('chat-1', 'msg-1', 'النص الجديد'))
              .thenAnswer((_) async => const Right(null));
        },
        build: buildCubit,
        act: (cubit) => cubit.editMessage(
          chatId: 'chat-1',
          messageId: 'msg-1',
          newText: 'النص الجديد',
        ),
        expect: () => const [
          ChatActorLoading(),
          ChatActorEditSuccess('msg-1'),
        ],
      );

      blocTest<ChatActorCubit, ChatActorState>(
        'emits [Loading, Error] when the repository rejects the edit',
        setUp: () {
          when(() => repository.editMessage('chat-1', 'msg-1', 'نص'))
              .thenAnswer((_) async => const Left(ServerFailure('مفيش صلاحية للتعديل')));
        },
        build: buildCubit,
        act: (cubit) => cubit.editMessage(
          chatId: 'chat-1',
          messageId: 'msg-1',
          newText: 'نص',
        ),
        expect: () => const [
          ChatActorLoading(),
          ChatActorError('مفيش صلاحية للتعديل'),
        ],
      );

      blocTest<ChatActorCubit, ChatActorState>(
        'validates the input inside the use case without touching the repository',
        build: buildCubit,
        act: (cubit) => cubit.editMessage(
          chatId: 'chat-1',
          messageId: 'msg-1',
          newText: '   ',
        ),
        expect: () => const [
          ChatActorLoading(),
          ChatActorError('لا يمكن حفظ رسالة فارغة'),
        ],
        verify: (_) {
          verifyNever(() => repository.editMessage(any(), any(), any()));
        },
      );

      blocTest<ChatActorCubit, ChatActorState>(
        'validates the ids inside the use case the same way',
        build: buildCubit,
        act: (cubit) => cubit.editMessage(
          chatId: '',
          messageId: 'msg-1',
          newText: 'نص سليم',
        ),
        expect: () => const [
          ChatActorLoading(),
          ChatActorError('بيانات التعديل غير صالحة'),
        ],
        verify: (_) {
          verifyNever(() => repository.editMessage(any(), any(), any()));
        },
      );
    });
  });
}
