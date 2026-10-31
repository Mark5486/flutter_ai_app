import 'package:flutter_ai_app/core/errors/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Failures', () {
    test('ServerFailure has a helpful default message', () {
      expect(const ServerFailure().message, 'حدث خطأ في الخادم');
    });

    test('ServerFailure accepts a custom message', () {
      expect(const ServerFailure('السيرفر واقع حاليًا').message, 'السيرفر واقع حاليًا');
    });

    test('two failures of the same type and message are equal', () {
      expect(const ServerFailure('نفس الخطأ'), const ServerFailure('نفس الخطأ'));
    });

    test('failures of different types are never equal even with same message', () {

      expect(const ServerFailure('نفس الرسالة'), isNot(const NetworkFailure('نفس الرسالة')));
    });
  });
}
