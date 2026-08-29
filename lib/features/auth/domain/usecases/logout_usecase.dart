import 'package:dartz/dartz.dart';
import 'package:flutter_ai_app/features/auth/domain/failures/auth_failure.dart';
import 'package:flutter_ai_app/features/auth/domain/repositories/auth_repository.dart';

class LogoutUseCase {
  final IAuthRepository _repository;

  const LogoutUseCase(this._repository);

  Future<Either<AuthFailure, Unit>> call() async {
    return await _repository.logout();
  }
}
