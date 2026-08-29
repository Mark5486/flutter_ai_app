import 'package:safe_device/safe_device.dart';

abstract interface class SecurityService {
  Future<bool> isRooted();
  Future<bool> isMockLocationEnabled();
  Future<bool> isRealDevice();
  Future<bool> isSecureDevice();
}

class SecurityServiceImpl implements SecurityService {
  @override
  Future<bool> isRooted() async {
    try {
      return await SafeDevice.isJailBroken;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isMockLocationEnabled() async {
    try {
      return await SafeDevice.isMockLocation;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isRealDevice() async {
    try {
      return await SafeDevice.isRealDevice;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<bool> isSecureDevice() async {
    final rooted = await isRooted();
    final mockLocation = await isMockLocationEnabled();

    return !rooted && !mockLocation;
  }
}
