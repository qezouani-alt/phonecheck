import 'package:flutter/foundation.dart';

import '../../models/device/phone_device_info.dart';
import 'device_info_service.dart';

class DeviceInfoController extends ChangeNotifier {
  DeviceInfoController({DeviceInfoService? service})
    : _service = service ?? const DeviceInfoService();
  final DeviceInfoService _service;
  Future<void>? _loadFuture;
  PhoneDeviceInfo? info;
  String? error;
  bool loading = false;
  bool refreshing = false;
  final Map<String, String> checks = {};
  final Set<String> checking = {};
  double? locationAccuracyMeters;

  Future<void> load() {
    if (info != null) return Future.value();
    return _loadFuture ??= _performLoad().whenComplete(
      () => _loadFuture = null,
    );
  }

  Future<void> _performLoad() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      info = await _service.load();
    } catch (exception) {
      error = exception is DeviceInfoUnavailable
          ? exception.message
          : 'Device information is unavailable on this device.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (info == null) {
      await load();
      return;
    }
    if (refreshing) return;
    refreshing = true;
    notifyListeners();
    try {
      info = await _service.refresh(info!);
      error = null;
    } catch (_) {
      error = 'Could not refresh live values. Pull down to try again.';
    } finally {
      refreshing = false;
      notifyListeners();
    }
  }

  Future<void> runCheck(String key, String method) async {
    if (checking.contains(key)) return;
    checking.add(key);
    notifyListeners();
    try {
      final response = await _service.check(method);
      checks[key] = response['status'] is String
          ? response['status'] as String
          : 'Unavailable';
      if (key == 'location' && response['accuracyMeters'] is num) {
        locationAccuracyMeters = (response['accuracyMeters'] as num).toDouble();
      }
    } catch (_) {
      checks[key] = 'Unavailable';
    } finally {
      checking.remove(key);
      notifyListeners();
    }
  }
}
