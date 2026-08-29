import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ai_app/core/services/routing_service.dart';
import 'package:flutter_ai_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_ai_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter_ai_app/main.dart';
import 'package:get_it/get_it.dart';

class FakeRoutingService implements RoutingService {
  @override
  Route<dynamic> generateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(body: Center(child: Text('Test Route'))),
    );
  }

  @override
  void navigateTo(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {}

  @override
  void navigateAndReplace(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {}

  @override
  void pop(BuildContext context) {
    Navigator.pop(context);
  }
}

class FakeAuthRepository implements IAuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();

    getIt.registerLazySingleton<RoutingService>(() => FakeRoutingService());

    getIt.registerFactory<AuthCubit>(() => AuthCubit(FakeAuthRepository()));
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('App builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
