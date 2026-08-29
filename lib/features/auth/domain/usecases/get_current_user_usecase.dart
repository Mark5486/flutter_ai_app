import 'package:dartz/dartz.dart';
import 'package:flutter_ai_app/features/auth/domain/repositories/auth_repository.dart';
import '../entities/user_entity.dart';

class GetCurrentUserUseCase {
  final IAuthRepository _repository;

  const GetCurrentUserUseCase(this._repository);

  Future<Option<UserEntity>> call() async {
    return await _repository.getCurrentUser();
  }
}
