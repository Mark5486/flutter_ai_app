import 'package:flutter/material.dart';
import 'package:flutter_ai_app/core/routes/app_router.dart';

abstract interface class RoutingService {
  Route<dynamic> generateRoute(RouteSettings settings);
  void navigateTo(BuildContext context, String routeName, {Object? arguments});
  void navigateAndReplace(
    BuildContext context,
    String routeName, {
    Object? arguments,
  });
  void pop(BuildContext context);
}

class RoutingServiceImpl implements RoutingService {
  @override
  Route<dynamic> generateRoute(RouteSettings settings) {
    return AppRouter.generateRoute(settings);
  }

  @override
  void navigateTo(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  @override
  void navigateAndReplace(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }

  @override
  void pop(BuildContext context) {
    Navigator.pop(context);
  }
}
