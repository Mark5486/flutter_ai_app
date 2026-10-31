import 'package:flutter_ai_app/features/chat/data/models/chat_message_model.dart';
import 'package:flutter_ai_app/features/chat/domain/entities/chat_message.dart';
import 'package:flutter_ai_app/features/chat/domain/entities/message_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_firebase_timestamp.dart';

void main() {
  group('ChatMessageModel.fromMap', () {
    test('parses a complete AI reply with thoughts, sources and edit metadata', () {
      final timestamp = DateTime(2024, 6, 1, 9, 29);
      final editedAt = DateTime(2024, 6, 1, 9, 30);

      final model = ChatMessageModel.fromMap({
        'text': 'ده الرد النهائي',
        'senderId': 'ai',
        'status': 'sent',
        'timestamp': FakeFirestoreTimestamp(timestamp),
        'thoughts': 'فكرت في السؤال وقسمته لخطوات',
        'sources': [
          {'title': 'ويكيبيديا', 'url': 'https://ar.wikipedia.org'},
        ],
        'isEdited': true,
        'editedAt': FakeFirestoreTimestamp(editedAt),
      }, 'doc-1');

      expect(model.id, 'doc-1');
      expect(model.sender, MessageSender.ai);
      expect(model.status, MessageStatus.sent);
      expect(model.timestamp, timestamp);
      expect(model.thoughts, 'فكرت في السؤال وقسمته لخطوات');
      expect(model.hasSources, isTrue);
      expect(model.sources.first.title, 'ويكيبيديا');
      expect(model.isEdited, isTrue);
      expect(model.editedAt, editedAt);
    });

    test('falls back to safe defaults when optional fields are missing', () {
      final model = ChatMessageModel.fromMap({
        'text': 'رسالة قديمة من نسخة سابقة',
      });

      expect(model.id, '');
      expect(model.sender, MessageSender.ai);
      expect(model.status, MessageStatus.sent);
      expect(model.hasImage, isFalse);
      expect(model.hasAudio, isFalse);
      expect(model.hasThoughts, isFalse);
      expect(model.hasSources, isFalse);
      expect(model.isEdited, isFalse);
      expect(model.editedAt, isNull);
    });

    test('understands the legacy "sender" field from early versions', () {
      final legacy = ChatMessageModel.fromMap({'sender': 'user'});

      expect(legacy.sender, MessageSender.user);
    });

    test('maps every stored status to its enum value', () {
      MessageStatus statusOf(dynamic stored) =>
          ChatMessageModel.fromMap({'status': stored}).status;

      expect(statusOf('sending'), MessageStatus.sending);
      expect(statusOf('failed'), MessageStatus.failed);
      expect(statusOf('sent'), MessageStatus.sent);
      expect(statusOf(null), MessageStatus.sent);
    });

    test('drops broken source entries and keeps only the valid ones', () {
      final model = ChatMessageModel.fromMap({
        'text': 'رد مبني على بحث',
        'sources': [
          'مش خريطة أصلاً',
          {'title': '', 'url': 'https://example.com'},
          {'title': 'عنوان من غير لينك'},
          {'title': 'مصدر سليم', 'url': 'https://example.com/valid'},
        ],
      });

      expect(model.hasSources, isTrue);
      expect(model.sources, hasLength(1));
      expect(model.sources.first.title, 'مصدر سليم');
    });
  });

  group('ChatMessageModel.toMap', () {
    test('serializes a user message with senderId and status', () {
      final model = ChatMessageModel(
        id: 'msg-1',
        text: 'ازيك',
        sender: MessageSender.user,
        timestamp: DateTime(2024, 6, 1, 9),
        status: MessageStatus.sent,
      );

      final map = model.toMap();

      expect(map['senderId'], 'user');
      expect(map['status'], 'sent');
      expect(map['text'], 'ازيك');
    });

    test('omits optional fields entirely when they are absent', () {
      final model = ChatMessageModel(
        id: 'msg-1',
        text: 'رسالة نصية عادية',
        sender: MessageSender.user,
        timestamp: DateTime(2024, 6, 1, 9),
      );

      final map = model.toMap();

      expect(map.containsKey('imageUrl'), isFalse);
      expect(map.containsKey('audioUrl'), isFalse);
      expect(map.containsKey('thoughts'), isFalse);
      expect(map.containsKey('sources'), isFalse);
      expect(map.containsKey('isEdited'), isFalse);
      expect(map.containsKey('editedAt'), isFalse);
    });

    test('includes thinking, sources and edit metadata only when present', () {
      final model = ChatMessageModel(
        id: 'msg-2',
        text: 'رد مبني على بحث',
        sender: MessageSender.ai,
        timestamp: DateTime(2024, 6, 1, 9),
        thoughts: 'خلاصة التفكير',
        sources: const [MessageSource(title: 'ويكي', url: 'https://ar.wikipedia.org')],
        isEdited: false,
      );

      final map = model.toMap();

      expect(map['thoughts'], 'خلاصة التفكير');
      expect(map['sources'], [
        {'title': 'ويكي', 'url': 'https://ar.wikipedia.org'},
      ]);

      expect(map.containsKey('isEdited'), isFalse);
    });
  });

  group('ChatMessageModel roundtrip', () {
    test('survives a full save-then-load cycle like the real Firestore flow', () {
      final timestamp = DateTime(2024, 6, 1, 9, 29);
      final editedAt = DateTime(2024, 6, 1, 9, 35);

      final model = ChatMessageModel(
        id: 'msg-9',
        text: 'الرسالة بعد التعديل',
        sender: MessageSender.user,
        timestamp: timestamp,
        status: MessageStatus.sent,
        isEdited: true,
        editedAt: editedAt,
        thoughts: 'ملحوظة تفكير',
        sources: const [MessageSource(title: 'مصدر', url: 'https://example.com')],
      );

      final persisted = model.toMap();

      persisted['timestamp'] = FakeFirestoreTimestamp(timestamp);
      persisted['editedAt'] = FakeFirestoreTimestamp(editedAt);

      final restored = ChatMessageModel.fromMap(persisted, 'msg-9');

      expect(restored.id, 'msg-9');
      expect(restored.text, 'الرسالة بعد التعديل');
      expect(restored.sender, MessageSender.user);
      expect(restored.status, MessageStatus.sent);
      expect(restored.timestamp, timestamp);
      expect(restored.isEdited, isTrue);
      expect(restored.editedAt, editedAt);
      expect(restored.thoughts, 'ملحوظة تفكير');
      expect(restored.sources.first.url, 'https://example.com');
    });

    test('toEntity copies every field into the domain entity', () {
      final timestamp = DateTime(2024, 6, 1, 9);
      const sources = [MessageSource(title: 'ويكي', url: 'https://ar.wikipedia.org')];

      final model = ChatMessageModel(
        id: 'msg-1',
        text: 'نص',
        sender: MessageSender.ai,
        timestamp: timestamp,
        thoughts: 'تفكير',
        sources: sources,
      );

      final entity = model.toEntity();

      expect(entity, isA<ChatMessage>());
      expect(entity.id, 'msg-1');
      expect(entity.text, 'نص');
      expect(entity.sender, MessageSender.ai);
      expect(entity.timestamp, timestamp);
      expect(entity.thoughts, 'تفكير');
      expect(entity.sources, sources);
    });
  });
}
