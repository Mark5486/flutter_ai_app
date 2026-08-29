abstract class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => message;
}

class ServerException extends AppException {
  const ServerException([super.message = 'حدث خطأ في الخادم']);
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'لا يوجد اتصال بالإنترنت']);
}

class CacheException extends AppException {
  const CacheException([super.message = 'حدث خطأ في التخزين المحلي']);
}

class AuthenticationException extends AppException {
  const AuthenticationException([super.message = 'فشل تسجيل الدخول']);
}

class PermissionException extends AppException {
  const PermissionException([super.message = 'ليس لديك الصلاحية المطلوبة']);
}

class FileException extends AppException {
  const FileException([super.message = 'حدث خطأ أثناء التعامل مع الملف']);
}

class AIException extends AppException {
  const AIException([
    super.message = 'حدث خطأ أثناء التواصل مع الذكاء الاصطناعي',
  ]);
}
