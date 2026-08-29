import 'package:dartz/dartz.dart';
import 'package:flutter_ai_app/features/auth/domain/repositories/auth_repository.dart';
import '../entities/user_entity.dart';
import '../failures/auth_failure.dart';

class SignInWithGoogleUseCase {
  final IAuthRepository _repository;

  const SignInWithGoogleUseCase(this._repository);

  Future<Either<AuthFailure, UserEntity>> call() async {
    return await _repository.signInWithGoogle();
  }
}
