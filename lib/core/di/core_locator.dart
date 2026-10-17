import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_ai_app/core/services/speech_to_text_service.dart';
import 'package:flutter_ai_app/core/services/text_to_speech_service.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/biometric_service.dart';
import '../services/device_service.dart';
import '../services/firebase_service.dart';
import '../services/local_storage_service.dart';
import '../services/routing_service.dart';
import '../services/security_service.dart';

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

  if (!getIt.isRegistered<FirebaseStorage>()) {
    getIt.registerLazySingleton<FirebaseStorage>(
      () => FirebaseStorage.instance,
    );
  }

  if (!getIt.isRegistered<GoogleSignIn>()) {
    getIt.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());
  }

  if (!getIt.isRegistered<LocalStorageService>()) {
    getIt.registerLazySingleton<LocalStorageService>(
      () => LocalStorageServiceImpl(getIt<SharedPreferences>()),
    );
  }

  if (!getIt.isRegistered<FirebaseService>()) {
    getIt.registerLazySingleton<FirebaseService>(() => FirebaseServiceImpl());
  }

  if (!getIt.isRegistered<DeviceInfoPlugin>()) {
    getIt.registerLazySingleton<DeviceInfoPlugin>(() => DeviceInfoPlugin());
  }

  if (!getIt.isRegistered<DeviceService>()) {
    getIt.registerLazySingleton<DeviceService>(
      () => DeviceServiceImpl(getIt<DeviceInfoPlugin>()),
    );
  }

  if (!getIt.isRegistered<LocalAuthentication>()) {
    getIt.registerLazySingleton<LocalAuthentication>(
      () => LocalAuthentication(),
    );
  }

  if (!getIt.isRegistered<BiometricService>()) {
    getIt.registerLazySingleton<BiometricService>(
      () => BiometricServiceImpl(getIt<LocalAuthentication>()),
    );
  }

  if (!getIt.isRegistered<SecurityService>()) {
    getIt.registerLazySingleton<SecurityService>(() => SecurityServiceImpl());
  }

  if (!getIt.isRegistered<RoutingService>()) {
    getIt.registerLazySingleton<RoutingService>(() => RoutingServiceImpl());
  }

  // AI credentials belong on the trusted backend, never in the client app.
  if (!getIt.isRegistered<VoiceInputService>()) {
    getIt.registerLazySingleton<VoiceInputService>(
      () => VoiceInputServiceImpl(),
    );
  }

  if (!getIt.isRegistered<TextToSpeechService>()) {
    getIt.registerLazySingleton<TextToSpeechService>(
      () => TextToSpeechServiceImpl(),
    );
  }
}
