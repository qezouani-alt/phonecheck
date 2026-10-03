import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkiphone/main.dart';
import 'package:checkiphone/models/device/phone_device_info.dart';
import 'package:checkiphone/screens/device_info/device_info_screen.dart';
import 'package:checkiphone/services/device/device_info_controller.dart';
import 'package:checkiphone/services/device/device_info_service.dart';

class _DeviceServiceForTest extends DeviceInfoService {
  _DeviceServiceForTest();
  int permissionChecks = 0;
  @override
  Future<PhoneDeviceInfo> load() async => PhoneDeviceInfo.fromMaps(
    {
      'identity': {
        'modelName': 'iPhone 15 Pro',
        'hardwareIdentifier': 'iPhone16,1',
        'deviceClass': 'iPhone',
        'localizedModel': 'iPhone',
        'isSimulator': false,
        'knownModel': true,
        'architecture': 'arm64',
        'systemName': 'iOS',
        'osVersion': '26.0.1',
      },
      'memory': {
        'physicalBytes': 8000000000,
        'processorCount': 6,
        'activeProcessorCount': 6,
      },
      'display': {
        'logicalWidth': 393,
        'logicalHeight': 852,
        'nativeWidth': 1179,
        'nativeHeight': 2556,
        'scale': 3,
        'nativeScale': 3,
        'maximumFramesPerSecond': 120,
      },
      'sensors': {
        'accelerometer': true,
        'gyroscope': true,
        'magnetometer': true,
        'deviceMotion': true,
      },
      'haptics': {'supported': true, 'audioSupported': true},
      'biometrics': {'type': 'Face ID', 'status': 'Not Enrolled'},
      'preferences': {'locale': 'en_US', 'region': 'US'},
      'app': {
        'version': '1.0.0',
        'build': '1',
        'bundleIdentifier': 'com.phonecheck.app',
      },
      'cameras': [
        {
          'position': 'Rear',
          'name': 'Back Triple Camera',
          'type': 'Triple',
          'connected': true,
          'virtual': true,
          'constituents': ['Wide', 'Ultra Wide', 'Telephoto'],
          'hasTorch': true,
          'torchAvailable': true,
          'hasFlash': true,
        },
      ],
    },
    {
      'battery': {
        'levelPercent': 82,
        'state': 'Unplugged',
        'powerConnected': false,
        'lowPowerMode': false,
      },
      'storage': {
        'totalBytes': 256000000000,
        'availableBytes': 142300000000,
        'usedBytes': 113700000000,
        'importantBytes': 140000000000,
      },
      'memoryDynamic': {'availableToProcessBytes': 2100000000},
      'systemStatus': {'thermalState': 'Nominal', 'lowPowerMode': false},
      'displayDynamic': {'brightnessPercent': 67},
      'network': {
        'status': 'Available',
        'interface': 'Wi-Fi',
        'expensive': false,
        'constrained': false,
      },
      'cellular': {},
    },
  );
  @override
  Future<PhoneDeviceInfo> refresh(PhoneDeviceInfo current) async => current;
  @override
  Future<Map<String, Object?>> check(String method) async {
    permissionChecks++;
    return {'status': 'Powered On'};
  }
}

void main() {
  testWidgets(
    'Device info shows live and reference sections without overflow on a small phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = _DeviceServiceForTest();
      final controller = DeviceInfoController(service: service);
      addTearDown(controller.dispose);
      await controller.load();
      await tester.pumpWidget(
        DeviceInfoScope(
          notifier: controller,
          child: const MaterialApp(home: DeviceInfoScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('iPhone 15 Pro'), findsWidgets);
      expect(find.text('82% Battery'), findsOneWidget);
      expect(find.text('142.3 GB Free'), findsOneWidget);
      expect(service.permissionChecks, 0);
      await tester.scrollUntilVisible(find.text('Model Specifications'), 300);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Model Specifications'));
      await tester.pumpAndSettle();
      expect(find.text('A17 Pro'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Connectivity'), -300);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Connectivity'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Check Bluetooth'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check Bluetooth'));
      await tester.pumpAndSettle();
      expect(service.permissionChecks, 1);
      expect(find.text('Powered On'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
