import 'package:flutter/material.dart';
import 'package:flutter_ai_app/core/constants/app_routes.dart';
import 'package:flutter_ai_app/features/attachment/presentation/screen/page/attachment_page.dart';
import 'package:flutter_ai_app/features/auth/presentation/screen/pages/auth_wrapper.dart';
import 'package:flutter_ai_app/features/auth/presentation/screen/views/home_view.dart';
import 'package:flutter_ai_app/features/auth/presentation/screen/views/login_view.dart';
import 'package:flutter_ai_app/features/auth/presentation/screen/views/register_view.dart';
import 'package:flutter_ai_app/features/chat/presentation/pages/chat_page.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.initial:
      case AppRoutes.authWrapper:
        return MaterialPageRoute(
          builder: (_) => const AuthWrapper(),
          settings: settings,
        );

      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => const LoginView(),
          settings: settings,
        );

      case AppRoutes.register:
        return MaterialPageRoute(
          builder: (_) => const RegisterView(),
          settings: settings,
        );

      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => const HomeView(),
          settings: settings,
        );

      case AppRoutes.chat:
        final chatId = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => ChatPage(chatId: chatId),
          settings: settings,
        );

      case AppRoutes.attachment:
        return MaterialPageRoute(
          builder: (_) => const AttachmentScreen(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder:
              (_) =>
                  const Scaffold(body: Center(child: Text('Page not found'))),
          settings: settings,
        );
    }
  }
}
