import 'package:dartz/dartz.dart';
import 'package:flutter_ai_app/features/auth/domain/repositories/auth_repository.dart';
import '../entities/user_entity.dart';
import '../failures/auth_failure.dart';

class LoginWithEmailUseCase {
  final IAuthRepository _repository;

  const LoginWithEmailUseCase(this._repository);

  Future<Either<AuthFailure, UserEntity>> call({
    required String email,
    required String password,
  }) async {
    return await _repository.loginWithEmail(
      email: email.trim(),
      password: password,
    );
  }
}
