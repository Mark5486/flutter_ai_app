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
    super.message = 'البريد الإلكتروني أو كلمة المرور غير صحيحة',
  ]);
}

class EmailAlreadyInUseFailure extends AuthFailure {
  const EmailAlreadyInUseFailure([
    super.message = 'البريد الإلكتروني مُسجّل بالفعل بحساب آخر',
  ]);
}

class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure([
    super.message = 'كلمة المرور ضعيفة جداً، يرجى اختيار كلمة مرور أقوى',
  ]);
}

class UserNotFoundFailure extends AuthFailure {
  const UserNotFoundFailure([
    super.message = 'لم يتم العثور على حساب مرتبطة بهذا البريد',
  ]);
}

class GoogleSignInCancelledFailure extends AuthFailure {
  const GoogleSignInCancelledFailure([
    super.message = 'تم إلغاء عملية تسجيل الدخول عبر Google',
  ]);
}

class NetworkAuthFailure extends AuthFailure {
  const NetworkAuthFailure([
    super.message = 'تحقق من الاتصال بالإنترنت وحاول مرة أخرى',
  ]);
}

class ServerAuthFailure extends AuthFailure {
  const ServerAuthFailure(super.message, {super.code});
}
