import 'package:firebase_auth/firebase_auth.dart';

import 'exceptions.dart';

mixin FirebaseErrorHandler {
  Exception handleFirebaseException(Object error) {
    if (error is FirebaseAuthException) {
      return _handleAuthException(error);
    }

    return ServerException(error.toString());
  }

  AuthenticationException _handleAuthException(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return const AuthenticationException('البريد الإلكتروني غير صحيح');

      case 'user-disabled':
        return const AuthenticationException('تم تعطيل هذا الحساب');

      case 'user-not-found':
        return const AuthenticationException('المستخدم غير موجود');

      case 'wrong-password':
      case 'invalid-credential':
        return const AuthenticationException(
          'البريد الإلكتروني أو كلمة المرور غير صحيحة',
        );

      case 'email-already-in-use':
        return const AuthenticationException('البريد الإلكتروني مستخدم بالفعل');

      case 'weak-password':
        return const AuthenticationException('كلمة المرور ضعيفة');

      case 'too-many-requests':
        return const AuthenticationException(
          'تم إجراء محاولات كثيرة، حاول مرة أخرى لاحقًا',
        );

      case 'network-request-failed':
        return const AuthenticationException('تحقق من اتصال الإنترنت');

      default:
        return AuthenticationException(
          error.message ?? 'حدث خطأ أثناء المصادقة',
        );
    }
  }
}
