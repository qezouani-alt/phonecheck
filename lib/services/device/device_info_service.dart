import 'dart:io';

import 'package:flutter/services.dart';

import '../../models/device/phone_device_info.dart';

class DeviceInfoService {
  const DeviceInfoService();
  static const channel = MethodChannel('com.phonecheck/device');

  Future<Map<String, Object?>> _call(String method) async {
    if (!Platform.isIOS) {
      throw const DeviceInfoUnavailable(
        'Device information is available on iPhone and iPad.',
      );
    }
    final response = await channel.invokeMapMethod<String, Object?>(method);
    if (response == null) {
      throw const DeviceInfoUnavailable('Device information is unavailable.');
    }
    return response;
  }

  Future<PhoneDeviceInfo> load() async {
    final staticData = await _call('getStaticInfo');
    final dynamicData = await _call('getDynamicInfo');
    return PhoneDeviceInfo.fromMaps(staticData, dynamicData);
  }

  Future<PhoneDeviceInfo> refresh(PhoneDeviceInfo current) async =>
      current.withDynamic(await _call('getDynamicInfo'));

  Future<Map<String, Object?>> check(String method) => _call(method);
}

class DeviceInfoUnavailable implements Exception {
  const DeviceInfoUnavailable(this.message);
  final String message;
  @override
  String toString() => message;
}
