import 'package:flutter_ai_app/features/chat/domain/entities/message_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MessageSource', () {
    test('toMap serializes title and url with the exact Firestore shape', () {
      const source = MessageSource(title: 'موسوعة ويكيبيديا', url: 'https://ar.wikipedia.org');

      expect(source.toMap(), {
        'title': 'موسوعة ويكيبيديا',
        'url': 'https://ar.wikipedia.org',
      });
    });

    test('two sources with the same title and url are equal', () {
      const first = MessageSource(title: 'ويكي', url: 'https://ar.wikipedia.org');
      const second = MessageSource(title: 'ويكي', url: 'https://ar.wikipedia.org');

      expect(first, second);
    });

    test('sources with different urls are not equal', () {
      const first = MessageSource(title: 'ويكي', url: 'https://ar.wikipedia.org');
      const second = MessageSource(title: 'ويكي', url: 'https://en.wikipedia.org');

      expect(first, isNot(second));
    });
  });
}
