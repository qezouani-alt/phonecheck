import 'dart:async';

import 'package:checkiphone/services/ads/tracking_transparency_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.phonecheck/tracking');
  final messenger = TestDefaultBinaryMessengerBinding
      .instance
      .defaultBinaryMessenger;

  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);
  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('concurrent ad loaders wait for one ATT response', () async {
    final response = Completer<int>();
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (call) {
      expect(call.method, 'requestAuthorization');
      calls++;
      return response.future;
    });

    final first = TrackingTransparencyService.ensureResolved();
    final second = TrackingTransparencyService.ensureResolved();
    expect(identical(first, second), isTrue);
    expect(calls, 1);

    response.complete(2); // Denied still resolves the ATT request.
    expect(await first, isTrue);
    expect(await second, isTrue);
  });

  test('unresolved or unavailable ATT keeps ads gated', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => 0);
    expect(await TrackingTransparencyService.ensureResolved(), isFalse);

    messenger.setMockMethodCallHandler(
      channel,
      (_) => throw PlatformException(code: 'unavailable'),
    );
    expect(await TrackingTransparencyService.ensureResolved(), isFalse);
  });
}
