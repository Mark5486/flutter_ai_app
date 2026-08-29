import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'حدث خطأ في الخادم']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'لا يوجد اتصال بالإنترنت']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'حدث خطأ في التخزين المحلي']);
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure([super.message = 'فشل تسجيل الدخول']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'ليس لديك الصلاحية المطلوبة']);
}

class FileFailure extends Failure {
  const FileFailure([super.message = 'حدث خطأ أثناء التعامل مع الملف']);
}

class AIFailure extends Failure {
  const AIFailure([
    super.message = 'حدث خطأ أثناء التواصل مع الذكاء الاصطناعي',
  ]);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'حدث خطأ غير متوقع']);
}
