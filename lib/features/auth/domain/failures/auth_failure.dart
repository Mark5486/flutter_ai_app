import 'package:equatable/equatable.dart';

abstract class AuthFailure extends Equatable {
  final String message;
  final String? code;

  const AuthFailure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

class InvalidEmailPasswordFailure extends AuthFailure {
  const InvalidEmailPasswordFailure([
    String message = 'البريد الإلكتروني أو كلمة المرور غير صحيحة',
  ]) : super(message);
}

class EmailAlreadyInUseFailure extends AuthFailure {
  const EmailAlreadyInUseFailure([
    String message = 'البريد الإلكتروني مُسجّل بالفعل بحساب آخر',
  ]) : super(message);
}

class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure([
    String message = 'كلمة المرور ضعيفة جداً، يرجى اختيار كلمة مرور أقوى',
  ]) : super(message);
}

class UserNotFoundFailure extends AuthFailure {
  const UserNotFoundFailure([
    String message = 'لم يتم العثور على حساب مرتبطة بهذا البريد',
  ]) : super(message);
}

class GoogleSignInCancelledFailure extends AuthFailure {
  const GoogleSignInCancelledFailure([
    String message = 'تم إلغاء عملية تسجيل الدخول عبر Google',
  ]) : super(message);
}

class NetworkAuthFailure extends AuthFailure {
  const NetworkAuthFailure([
    String message = 'تحقق من الاتصال بالإنترنت وحاول مرة أخرى',
  ]) : super(message);
}

class ServerAuthFailure extends AuthFailure {
  const ServerAuthFailure(String message, {String? code})
    : super(message, code: code);
}
