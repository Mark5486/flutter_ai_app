import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/firebase_service.dart';
import '../services/routing_service.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupCoreLocator() async {
  final preferences = await SharedPreferences.getInstance();
  if (!getIt.isRegistered<SharedPreferences>()) {
    getIt.registerSingleton<SharedPreferences>(preferences);
  }

  if (!getIt.isRegistered<FirebaseAuth>()) {
    getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  }

  if (!getIt.isRegistered<FirebaseFirestore>()) {
    getIt.registerLazySingleton<FirebaseFirestore>(
      () => FirebaseFirestore.instance,
    );
  }

  if (!getIt.isRegistered<GoogleSignIn>()) {
    getIt.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());
  }

  if (!getIt.isRegistered<FirebaseService>()) {
    getIt.registerLazySingleton<FirebaseService>(() => FirebaseServiceImpl());
  }

  if (!getIt.isRegistered<RoutingService>()) {
    getIt.registerLazySingleton<RoutingService>(() => RoutingServiceImpl());
  }
}
