import 'package:dartz/dartz.dart';
import 'package:flutter_ai_app/features/auth/domain/repositories/auth_repository.dart';
import '../entities/user_entity.dart';
import '../failures/auth_failure.dart';

class RegisterWithEmailUseCase {
  final IAuthRepository _repository;

  const RegisterWithEmailUseCase(this._repository);

  Future<Either<AuthFailure, UserEntity>> call({
    required String name,
    required String email,
    required String password,
  }) async {
    return await _repository.registerWithEmail(
      name: name.trim(),
      email: email.trim(),
      password: password,
    );
  }
}
