import 'package:flutter/material.dart';
import 'package:flutter_ai_app/core/constants/app_routes.dart';
import 'package:flutter_ai_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter_ai_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter_ai_app/features/auth/presentation/screen/widgets/auth_header.dart';
import 'package:flutter_ai_app/features/auth/presentation/screen/widgets/custom_primary_button.dart';
import 'package:flutter_ai_app/features/auth/presentation/screen/widgets/custom_social_button.dart';
import 'package:flutter_ai_app/features/auth/presentation/screen/widgets/custom_text_field.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ai_app/core/utils/validators.dart';

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
        password: _passwordController.text,
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
              const SizedBox(height: 36),
              CustomTextField(
                controller: _emailController,
                label: 'البريد الإلكتروني',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                label: 'كلمة المرور',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                validator:
                    (value) => Validators.required(
                      value,
                      message: 'كلمة المرور مطلوبة',
                    ),
              ),
              const SizedBox(height: 28),
              CustomPrimaryButton(
                text: 'تسجيل الدخول',
                isLoading: isLoading,
                onPressed: _onLoginPressed,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'أو',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 18),
              CustomSocialButton(
                label: 'تسجيل بواسطة Google',
                icon: Icons.g_mobiledata,
                isLoading: isLoading,
                onPressed: () => context.read<AuthCubit>().signInWithGoogle(),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.register);
                },
                child: Text.rich(
                  TextSpan(
                    text: 'ليس لديك حساب؟ ',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                    children: const [
                      TextSpan(
                        text: 'أنشئ حساباً الآن',
                        style: TextStyle(
                          color: Color(0xFF9F7BFF),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
