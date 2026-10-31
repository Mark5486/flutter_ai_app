import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_app/core/constants/app_routes.dart';
import 'package:flutter_ai_app/core/di/auth_locator.dart';
import 'package:flutter_ai_app/core/services/routing_service.dart';
import 'package:flutter_ai_app/core/theme/app_theme.dart';
import 'package:flutter_ai_app/core/utils/service_locator.dart';
import 'package:flutter_ai_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter_ai_app/firebase_options.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await initServiceLocator();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final routingService = getIt<RoutingService>();

    return BlocProvider<AuthCubit>(
      create: (context) => getIt<AuthCubit>(),
      child: MaterialApp(
        title: 'AI Smart Assistant',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        initialRoute: AppRoutes.initial,
        onGenerateRoute: routingService.generateRoute,
        
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
          },
        ),
        
        builder:
            (context, child) => MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.4,
              child: child!,
            ),
      ),
    );
  }
}
