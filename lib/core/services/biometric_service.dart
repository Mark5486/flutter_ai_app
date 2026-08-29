import 'package:local_auth/local_auth.dart';

abstract interface class BiometricService {
  Future<bool> isAvailable();
  Future<bool> authenticate();
  Future<List<BiometricType>> getAvailableBiometrics();
}

class BiometricServiceImpl implements BiometricService {
  final LocalAuthentication _localAuth;

  const BiometricServiceImpl(this._localAuth);

  @override
  Future<bool> isAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics &&
          await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticate() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'قم بتأكيد هويتك للمتابعة',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }
}
