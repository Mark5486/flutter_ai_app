import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final IAuthRepository _authRepository;
  StreamSubscription? _authSubscription;

  AuthCubit(this._authRepository) : super(AuthInitial()) {
    _monitorAuthState();
  }

  void _monitorAuthState() {
    _authSubscription?.cancel();
    _authSubscription = _authRepository.authStateChanges.listen((userOption) {
      userOption.fold(
        () => emit(Unauthenticated()),
        (user) => emit(Authenticated(user)),
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

    result.fold(
      (failure) {
        print('🔥 LOGIN ERROR: ${failure.message}');
        emit(AuthFailureState(failure.message));
      },
      (_) {
        print('✅ LOGIN SUCCESS');
      },
    );
  }

  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());

    print('🚀 REGISTER START');
    print('📧 Email: $email');
    print('👤 Name: $name');

    final result = await _authRepository.registerWithEmail(
      name: name,
      email: email,
      password: password,
    );

    result.fold(
      (failure) {
        print('🔥 REGISTER ERROR: ${failure.message}');
        emit(AuthFailureState(failure.message));
      },
      (_) {
        print('✅ REGISTER SUCCESS');
      },
    );
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    final result = await _authRepository.signInWithGoogle();

    result.fold(
      (failure) {
        print('🔥 GOOGLE LOGIN ERROR: ${failure.message}');
        emit(AuthFailureState(failure.message));
      },
      (_) {
        print('✅ GOOGLE LOGIN SUCCESS');
      },
    );
  }

  Future<void> signInAnonymously() async {
    emit(AuthLoading());
    final result = await _authRepository.signInAnonymously();

    result.fold(
      (failure) {
        print('🔥 ANONYMOUS LOGIN ERROR: ${failure.message}');
        emit(AuthFailureState(failure.message));
      },
      (_) {
        print('✅ ANONYMOUS LOGIN SUCCESS');
      },
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    emit(AuthLoading());
    final result = await _authRepository.sendPasswordResetEmail(email);

    result.fold(
      (failure) {
        print('🔥 PASSWORD RESET ERROR: ${failure.message}');
        emit(AuthFailureState(failure.message));
      },
      (_) {
        print('✅ PASSWORD RESET SUCCESS');
        emit(Unauthenticated());
      },
    );
  }

  Future<void> logout() async {
    emit(AuthLoading());
    final result = await _authRepository.logout();

    result.fold(
      (failure) {
        print('🔥 LOGOUT ERROR: ${failure.message}');
        emit(AuthFailureState(failure.message));
      },
      (_) {
        print('✅ LOGOUT SUCCESS');
      },
    );
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
