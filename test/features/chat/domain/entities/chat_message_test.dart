import 'package:flutter_ai_app/features/chat/domain/entities/chat_message.dart';
import 'package:flutter_ai_app/features/chat/domain/entities/message_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/mock_chat_repository.dart';

void main() {
  group('ChatMessage', () {
    group('canBeEdited', () {
      test('is true for a sent user message with text', () {
        final message = fakeChatMessage();

        expect(message.canBeEdited, isTrue);
      });

      test('is false for an AI message', () {
        final message = fakeChatMessage(sender: MessageSender.ai);

        expect(message.canBeEdited, isFalse);
      });

      test('is false for a message that is still sending', () {
        final message = fakeChatMessage(status: MessageStatus.sending);

        expect(message.canBeEdited, isFalse);
      });
    });

    group('hasThoughts', () {
      test('is false when thoughts are null', () {
        expect(fakeChatMessage().hasThoughts, isFalse);
      });

      test('is false when thoughts are only whitespace', () {
        expect(fakeChatMessage(thoughts: '   ').hasThoughts, isFalse);
      });

      test('is true when there is a real thought summary', () {
        expect(fakeChatMessage(thoughts: 'فكرت في المسألة خطوة بخطوة').hasThoughts, isTrue);
      });
    });

    group('hasSources', () {
      test('is false with an empty sources list', () {
        expect(fakeChatMessage(sources: const []).hasSources, isFalse);
      });

      test('is true with at least one source', () {
        const sources = [MessageSource(title: 'ويكيبيديا', url: 'https://ar.wikipedia.org')];

        expect(fakeChatMessage(sources: sources).hasSources, isTrue);
      });
    });

    group('equality (Equatable)', () {
      test('two identical messages are equal', () {
        final first = fakeChatMessage();
        final second = fakeChatMessage();

        expect(first, second);
      });

      test('editing metadata changes the message identity', () {
        final original = fakeChatMessage();
        final edited = fakeChatMessage(isEdited: true, editedAt: DateTime(2024, 5, 2));

        expect(original, isNot(edited));
      });
    });
  });
}
