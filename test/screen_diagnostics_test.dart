import 'package:checkiphone/data/inspection_store.dart';
import 'package:checkiphone/data/mock_test_data.dart';
import 'package:checkiphone/models/test_item.dart';
import 'package:checkiphone/models/device/phone_device_info.dart';
import 'package:checkiphone/models/touch_grid_coverage.dart';
import 'package:checkiphone/screens/test_detail/brightness_test_view.dart';
import 'package:checkiphone/screens/test_detail/display_test_view.dart';
import 'package:checkiphone/screens/test_detail/touch_test_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'touch coverage includes every cell crossed by fast and diagonal drags',
    () {
      final coverage = TouchGridCoverage();
      const size = Size(100, 100);
      coverage.markSegment(const Offset(5, 5), const Offset(95, 5), size);
      expect(coverage.count, 10);
      coverage.reset();
      coverage.markSegment(const Offset(5, 5), const Offset(95, 95), size);
      expect(coverage.count, greaterThanOrEqualTo(10));
      expect(coverage.touched, containsAll([0, 99]));
    },
  );

  test('inspection session keeps results and resets on a new inspection', () {
    final store = InspectionStore();
    final device = PhoneDeviceInfo.fromMaps(
      {
        'identity': {'modelName': 'iPhone 18 Pro', 'osVersion': '27.0'},
      },
      {
        'storage': {'totalBytes': 256000000000},
      },
    );
    store.begin(device);
    final first = store.session!;
    expect(first.deviceInfoSnapshot?.model, 'iPhone 18 Pro');
    expect(first.deviceInfoSnapshot?.storageTotalBytes, 256000000000);
    store.setStatus('touch', TestStatus.attention);
    expect(first.testResults['touch'], TestStatus.attention);
    expect(store.current.date, first.startedAt);

    store.begin(null);
    expect(store.session!.testResults, isEmpty);
    expect(store.status('touch'), TestStatus.pending);
    expect(first.testResults['touch'], TestStatus.attention);
    store.dispose();
  });

  testWidgets(
    'multi-touch counts simultaneous pointers and keeps the maximum',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: MultiTouchView(item: MockTestData.item('multi'))),
      );
      await tester.tap(find.text('Begin Test'));
      await tester.pumpAndSettle();
      final area = tester.getRect(
        find.byKey(const ValueKey('multi-touch-area')),
      );
      expect(
        area.size,
        tester.view.physicalSize / tester.view.devicePixelRatio,
      );
      final first = await tester.createGesture(pointer: 1);
      final second = await tester.createGesture(pointer: 2);
      await first.down(area.centerLeft + const Offset(50, 0));
      await second.down(area.centerRight - const Offset(50, 0));
      await tester.pump();
      expect(find.textContaining('Active Touches 2'), findsOneWidget);
      expect(
        find.textContaining('Maximum Simultaneous Touches Detected 2'),
        findsOneWidget,
      );
      await first.up();
      await second.up();
      await tester.pump();
      expect(find.textContaining('Active Touches 0'), findsOneWidget);
      expect(
        find.textContaining('Maximum Simultaneous Touches Detected 2'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'display tests are edge-to-edge solid-color canvases and support both directions',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: DisplayTestView(
            key: const ValueKey('pixel-test'),
            item: MockTestData.item('pixel'),
          ),
        ),
      );
      await tester.tap(find.text('Begin Test'));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(const ValueKey('display-color-area'))).size,
        const Size(320, 568),
      );
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.textContaining('1 / 5'), findsNothing);
      await tester.tapAt(const Offset(275, 270));
      await tester.pump();
      expect(find.textContaining('2 / 5'), findsNothing);
      await tester.tapAt(const Offset(35, 270));
      await tester.pump();
      expect(find.textContaining('1 / 5'), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          home: DisplayTestView(
            key: const ValueKey('oled-test'),
            item: MockTestData.item('oled'),
          ),
        ),
      );
      expect(
        find.text(
          'Look for ghost images, uneven areas, permanent shapes, or color tinting.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Begin Test'));
      await tester.pumpAndSettle();
      for (var index = 2; index <= 7; index++) {
        await tester.tapAt(const Offset(275, 270));
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('brightness slider changes only the in-app preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BrightnessTestView(item: MockTestData.item('brightness')),
      ),
    );
    await tester.tap(find.text('Begin Test'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('brightness-surface')), findsOneWidget);
    await tester.tapAt(const Offset(400, 300));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('This slider changes only the preview'),
      findsOneWidget,
    );
    final before = tester.widget<Slider>(find.byType(Slider)).value;
    await tester.drag(find.byType(Slider), const Offset(90, 0));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Slider>(find.byType(Slider)).value,
      greaterThan(before),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('fullscreen mode hides and restores iOS overlays on route pop', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    DisplayTestView(item: MockTestData.item('pixel')),
              ),
            ),
            child: const Text('Open display test'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open display test'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Begin Test'));
    await tester.pumpAndSettle();
    final modeCalls = calls.where(
      (call) => call.method == 'SystemChrome.setEnabledSystemUIOverlays',
    );
    expect(modeCalls.last.arguments, isEmpty);
    Navigator.of(
      tester.element(find.byKey(const ValueKey('display-color-area'))),
    ).pop();
    await tester.pumpAndSettle();
    expect(modeCalls.last.arguments, [
      'SystemUiOverlay.top',
      'SystemUiOverlay.bottom',
    ]);
  });
}
