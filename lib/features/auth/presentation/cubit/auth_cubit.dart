import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final IAuthRepository _authRepository;
  StreamSubscription? _authSubscription;
  UserEntity? _currentUser;

  UserEntity? get currentUser => _currentUser;

  AuthCubit(this._authRepository) : super(AuthInitial()) {
    _monitorAuthState();
  }

  void _monitorAuthState() {
    _authSubscription?.cancel();
    _authSubscription = _authRepository.authStateChanges.listen((userOption) {
      userOption.fold(
        () {
          _currentUser = null;
          emit(Unauthenticated());
        },
        (user) {
          _currentUser = user;
          emit(Authenticated(user));
        },
      );
    });
  }

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());

    final result = await _authRepository.loginWithEmail(
      email: email,
      password: password,
    );

    result.fold((failure) {
      emit(AuthFailureState(failure.message));
    }, (_) {});
  }

  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());

    final result = await _authRepository.registerWithEmail(
      name: name,
      email: email,
      password: password,
    );

    result.fold((failure) {
      emit(AuthFailureState(failure.message));
    }, (_) {});
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    final result = await _authRepository.signInWithGoogle();

    result.fold((failure) {
      emit(AuthFailureState(failure.message));
    }, (_) {});
  }

  Future<void> sendPasswordResetEmail(String email) async {
    emit(AuthLoading());
    final result = await _authRepository.sendPasswordResetEmail(email);

    result.fold(
      (failure) {
        emit(AuthFailureState(failure.message));
      },
      (_) {
        emit(Unauthenticated());
      },
    );
  }

  Future<void> logout() async {
    emit(AuthLoading());
    final result = await _authRepository.logout();

    result.fold((failure) {
      emit(AuthFailureState(failure.message));
    }, (_) {});
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    return super.close();
  }
}
