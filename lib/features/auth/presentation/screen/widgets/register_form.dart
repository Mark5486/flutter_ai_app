import 'package:flutter/material.dart';
import 'package:flutter_ai_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter_ai_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter_ai_app/features/auth/presentation/screen/widgets/auth_header.dart';
import 'package:flutter_ai_app/features/auth/presentation/screen/widgets/custom_primary_button.dart';
import 'package:flutter_ai_app/features/auth/presentation/screen/widgets/custom_text_field.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRegisterPressed() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().registerWithEmail(
        name: _nameController.text.trim(),
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
            children: [
              const AuthHeader(
                title: 'إنشاء حساب جديد',
                subtitle:
                    'قم بإنشاء حسابك للاستفادة من مميزات الذكاء الاصطناعي',
              ),
              const SizedBox(height: 32),
              CustomTextField(
                controller: _nameController,
                label: 'الاسم الكامل',
                prefixIcon: Icons.person_outline,
                validator:
                    (val) =>
                        val != null && val.trim().isNotEmpty
                            ? null
                            : 'أدخل الاسم',
              ),
              const SizedBox(height: 16),
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
                text: 'إنشاء الحساب',
                isLoading: isLoading,
                onPressed: _onRegisterPressed,
              ),
            ],
          ),
        );
      },
    );
  }
}
