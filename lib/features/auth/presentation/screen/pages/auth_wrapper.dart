import 'package:flutter/material.dart';
import 'package:flutter_ai_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter_ai_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter_ai_app/features/auth/presentation/screen/views/home_view.dart';
import 'package:flutter_ai_app/features/auth/presentation/screen/views/login_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          return const HomeView();
        } else if (state is AuthFailureState &&
            context.read<AuthCubit>().currentUser != null) {
          return const HomeView();
        } else if (state is Unauthenticated ||
            state is AuthFailureState ||
            (state is AuthLoading &&
                context.read<AuthCubit>().currentUser == null)) {
          return const LoginView();
        } else if (state is AuthLoading &&
            context.read<AuthCubit>().currentUser != null) {
          return const HomeView();
        } else {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator.adaptive()),
          );
        }
      },
    );
  }
}
