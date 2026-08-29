import 'package:device_info_plus/device_info_plus.dart';

abstract interface class DeviceService {
  Future<String> getDeviceId();

  Future<String> getDeviceName();

  Future<String> getPlatform();

  Future<String> getAppVersion();
}

class DeviceServiceImpl implements DeviceService {
  final DeviceInfoPlugin _deviceInfo;

  const DeviceServiceImpl(this._deviceInfo);

  @override
  Future<String> getDeviceId() async {
    if (const bool.fromEnvironment('dart.library.io')) {
      final android = await _deviceInfo.androidInfo;

      return android.id;
    }

    return 'unknown';
  }

  @override
  Future<String> getDeviceName() async {
    final android = await _deviceInfo.androidInfo;

    return android.model;
  }

  @override
  Future<String> getPlatform() async {
    final android = await _deviceInfo.androidInfo;

    return 'Android ${android.version.release}';
  }

  @override
  Future<String> getAppVersion() async {
    return '1.0.0';
  }
}
