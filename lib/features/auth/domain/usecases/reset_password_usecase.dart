import 'package:dartz/dartz.dart';
import 'package:flutter_ai_app/features/auth/domain/repositories/auth_repository.dart';
import '../failures/auth_failure.dart';

class ResetPasswordUseCase {
  final IAuthRepository _repository;

  const ResetPasswordUseCase(this._repository);

  Future<Either<AuthFailure, Unit>> call(String email) async {
    return await _repository.sendPasswordResetEmail(email.trim());
  }
}
