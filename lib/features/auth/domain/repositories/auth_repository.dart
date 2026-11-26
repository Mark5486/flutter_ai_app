import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';
import '../failures/auth_failure.dart';

abstract interface class IAuthRepository {
  Stream<Option<UserEntity>> get authStateChanges;

  Future<Option<UserEntity>> getCurrentUser();

  Future<Either<AuthFailure, UserEntity>> loginWithEmail({
    required String email,
    required String password,
  });

  Future<Either<AuthFailure, UserEntity>> registerWithEmail({
    required String name,
    required String email,
    required String password,
  });

  Future<Either<AuthFailure, UserEntity>> signInWithGoogle();

  Future<Either<AuthFailure, Unit>> sendPasswordResetEmail(String email);

  Future<Either<AuthFailure, Unit>> logout();
}
