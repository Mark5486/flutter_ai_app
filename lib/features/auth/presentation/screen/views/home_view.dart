import 'package:flutter/material.dart';
import 'package:flutter_ai_app/core/constants/app_routes.dart';
import 'package:flutter_ai_app/core/theme/app_theme.dart';
import 'package:flutter_ai_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter_ai_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) => current is AuthFailureState,
      listener: (context, state) {
        if (state is AuthFailureState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.pageGradient),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 48,
                      maxWidth: 640,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.glow,
                    ),
                    child: const Icon(
                      Icons.smart_toy_rounded,
                      color: Colors.white,
                      size: 58,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'أهلاً بك في مساعدك الذكي',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'اسأل، ارفع صور، ابعت صوت — والذكاء الاصطناعي يجاوبك',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AppTheme.softGlow,
                    ),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text(
                        'ابدأ المحادثة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.chat);
                      },
                    ),
                  ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppTheme.surfaceHigh,
          foregroundColor: Colors.white70,
          onPressed: () => context.read<AuthCubit>().logout(),
          child: const Icon(Icons.logout_rounded),
        ),
      ),
    );
  }
}
