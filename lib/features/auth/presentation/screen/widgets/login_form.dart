import 'package:flutter/material.dart';
import 'package:flutter_ai_app/core/constants/app_routes.dart';
import 'package:flutter_ai_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter_ai_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter_ai_app/features/auth/presentation/screen/widgets/auth_header.dart';
import 'package:flutter_ai_app/features/auth/presentation/screen/widgets/custom_primary_button.dart';
import 'package:flutter_ai_app/features/auth/presentation/screen/widgets/custom_social_button.dart';
import 'package:flutter_ai_app/features/auth/presentation/screen/widgets/custom_text_field.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().loginWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AuthHeader(
                title: 'مرحباً بك مجدداً',
                subtitle: 'سجل دخولك لمتابعة استخدام المساعد الذكي',
              ),
              const SizedBox(height: 32),
              CustomTextField(
                controller: _emailController,
                label: 'البريد الإلكتروني',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator:
                    (val) =>
                        val != null && val.contains('@')
                            ? null
                            : 'بريد غير صالح',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                label: 'كلمة المرور',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                validator:
                    (val) =>
                        val != null && val.length >= 6
                            ? null
                            : 'كلمة المرور قصيرة',
              ),
              const SizedBox(height: 24),
              CustomPrimaryButton(
                text: 'تسجيل الدخول',
                isLoading: isLoading,
                onPressed: _onLoginPressed,
              ),
              const SizedBox(height: 12),
              CustomSocialButton(
                label: 'تسجيل بواسطة Google',
                icon: Icons.g_mobiledata,
                isLoading: isLoading,
                onPressed: () => context.read<AuthCubit>().signInWithGoogle(),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.register);
                },
                child: const Text('ليس لديك حساب؟ أنشئ حساباً الآن'),
              ),
            ],
          ),
        );
      },
    );
  }
}
