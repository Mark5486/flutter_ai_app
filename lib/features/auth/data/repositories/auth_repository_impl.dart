import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ai_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_ai_app/features/auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/failures/auth_failure.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Stream<Option<UserEntity>> get authStateChanges {
    return _remoteDataSource.authStateChanges.map(
      (userModel) => optionOf(userModel),
    );
  }

  @override
  Future<Option<UserEntity>> getCurrentUser() async {
    final user = await _remoteDataSource.getCurrentUser();
    return optionOf(user);
  }

  @override
  Future<Either<AuthFailure, UserEntity>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remoteDataSource.loginWithEmail(email, password);
      return Right(user);
    } on FirebaseAuthException catch (e) {
      return Left(_handleFirebaseAuthException(e));
    } on FirebaseException catch (e) {
      return Left(ServerAuthFailure(e.message ?? 'خطأ في الاتصال بالخادم'));
    } catch (e) {
      return Left(ServerAuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, UserEntity>> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remoteDataSource.registerWithEmail(
        name,
        email,
        password,
      );

      return Right(user);
    } on FirebaseAuthException catch (e) {
      return Left(_handleFirebaseAuthException(e));
    } on FirebaseException catch (e) {
      return Left(ServerAuthFailure(e.message ?? 'خطأ في الاتصال بالخادم'));
    } catch (e) {
      return Left(ServerAuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, UserEntity>> signInWithGoogle() async {
    try {
      final user = await _remoteDataSource.signInWithGoogle();
      return Right(user);
    } on FormatException catch (e) {
      if (e.message == 'CANCELED_BY_USER') {
        return const Left(GoogleSignInCancelledFailure());
      }
      return Left(ServerAuthFailure(e.toString()));
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled') {
        return const Left(GoogleSignInCancelledFailure());
      }
      return Left(
        ServerAuthFailure(e.message ?? 'خطأ في تسجيل الدخول بـ Google'),
      );
    } on FirebaseAuthException catch (e) {
      return Left(_handleFirebaseAuthException(e));
    } catch (e) {
      return Left(ServerAuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, UserEntity>> signInAnonymously() async {
    try {
      final user = await _remoteDataSource.signInAnonymously();
      return Right(user);
    } on FirebaseAuthException catch (e) {
      return Left(_handleFirebaseAuthException(e));
    } catch (e) {
      return Left(ServerAuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> sendPasswordResetEmail(String email) async {
    try {
      await _remoteDataSource.sendPasswordResetEmail(email);
      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      return Left(_handleFirebaseAuthException(e));
    } catch (e) {
      return Left(ServerAuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> logout() async {
    try {
      await _remoteDataSource.logout();
      return const Right(unit);
    } catch (e) {
      return Left(ServerAuthFailure(e.toString()));
    }
  }

  /// Exception Handler Mapping
  AuthFailure _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return const InvalidEmailPasswordFailure();
      case 'email-already-in-use':
        return const EmailAlreadyInUseFailure();
      case 'weak-password':
        return const WeakPasswordFailure();
      case 'network-request-failed':
        return const NetworkAuthFailure();
      default:
        return ServerAuthFailure(
          e.message ?? 'حدث خطأ في عملية تسجيل الدخول',
          code: e.code,
        );
    }
  }
}
