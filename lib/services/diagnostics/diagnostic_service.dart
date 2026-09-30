import 'package:flutter/services.dart';

class DiagnosticService {
  static const channel = MethodChannel('com.phonecheck/diagnostics');
  static const device = MethodChannel('com.phonecheck/device');
  Future<Map<String, Object?>> call(
    String method, [
    Map<String, Object?>? args,
  ]) async => Map<String, Object?>.from(
    await channel.invokeMapMethod<String, Object?>(method, args) ?? {},
  );
  Future<void> action(String method) => channel.invokeMethod<void>(method);
  Future<void> stop() async {
    try {
      await channel.invokeMethod<void>('stop');
    } catch (_) {}
    try {
      await device.invokeMethod<void>('cancelLocation');
    } catch (_) {}
  }

  Future<Map<String, Object?>> connectivity(String id) async {
    if (id == 'bluetooth' || id == 'gps') {
      final response = await device.invokeMapMethod<String, Object?>(
        id == 'gps' ? 'checkLocation' : 'checkBluetooth',
      );
      final data = Map<String, Object?>.from(response ?? {});
      final status = data['status'] as String? ?? 'Unknown';
      return {
        'status': ['Denied', 'Restricted', 'Unauthorized'].contains(status)
            ? 'permission'
            : [
                'Unsupported',
                'Unavailable',
                'Timed Out',
                'Location Services Off',
                'Interrupted',
              ].contains(status)
            ? 'unavailable'
            : 'ready',
        'message': id == 'gps' && status == 'Available'
            ? 'Location signal received'
            : status,
        'measured': {
          if (id == 'gps') 'Location update received': status == 'Available',
          if (data['accuracyMeters'] != null)
            'Accuracy (m)': data['accuracyMeters'],
          if (id == 'bluetooth') 'Bluetooth state': status,
        },
      };
    }
    final data =
        await device.invokeMapMethod<String, Object?>('getDynamicInfo') ?? {};
    final values = Map<String, Object?>.from(
      data[id == 'wifi' ? 'network' : 'cellular'] as Map? ?? {},
    );
    return {
      'status': 'ready',
      'message': id == 'wifi'
          ? 'Current network path only. A connection does not prove Wi-Fi hardware health.'
          : 'Check SIM/eSIM service, signal and mobile data yourself. Public carrier data may be unavailable.',
      'measured': {
        for (final e in values.entries)
          if (e.value != null)
            switch (e.key) {
              'status' => 'Network path',
              'interface' => 'Interface',
              'expensive' => 'Metered connection',
              'constrained' => 'Low Data Mode',
              'radioTechnology' => 'Radio technology',
              _ => e.key,
            }: e.value,
      },
    };
  }
}
