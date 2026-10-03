import 'package:checkiphone/data/inspection_store.dart';
import 'package:checkiphone/data/mock_test_data.dart';
import 'package:checkiphone/main.dart';
import 'package:checkiphone/models/test_item.dart';
import 'package:checkiphone/screens/test_detail/touch_test_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _openControls(WidgetTester tester, String key) async {
  final area = tester.getRect(find.byKey(ValueKey(key)));
  final first = await tester.createGesture(pointer: 41);
  final second = await tester.createGesture(pointer: 42);
  await first.down(area.center + const Offset(-40, 0));
  await second.down(area.center + const Offset(40, 0));
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pumpAndSettle();
  await first.up();
  await second.up();
}

void main() {
  testWidgets('Home begins a full inspection with a device snapshot', (
    tester,
  ) async {
    await tester.pumpWidget(const PhoneCheckApp());
    expect(find.text('PhoneCheck'), findsOneWidget);
    await tester.tap(find.text('Start Full Test'));
    await tester.pumpAndSettle();
    final start = find.text('Start Inspection');
    expect(start, findsOneWidget);
    expect(InspectionScope.of(tester.element(start)).session, isNotNull);
  });

  testWidgets(
    'grid diagnostic is edge-to-edge and reveals controls only on the hold gesture',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = InspectionStore();
      addTearDown(store.dispose);
      await tester.pumpWidget(
        InspectionScope(
          notifier: store,
          child: MaterialApp(
            home: TouchTestView(item: MockTestData.item('touch')),
          ),
        ),
      );
      await tester.tap(find.text('Begin Test'));
      await tester.pumpAndSettle();
      final grid = find.byKey(const ValueKey('touch-grid'));
      expect(tester.getRect(grid).size, const Size(320, 568));
      expect(find.text('Finish Test'), findsNothing);
      expect(find.text('Reset'), findsNothing);
      await _openControls(tester, 'touch-grid');
      expect(find.text('Finish Test'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(find.textContaining('0% covered'), findsOneWidget);
    },
  );

  testWidgets('grid passes at 100 percent and fails after 30 seconds', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = InspectionStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(
      InspectionScope(
        notifier: store,
        child: MaterialApp(
          home: TouchTestView(
            key: const ValueKey('pass-grid'),
            item: MockTestData.item('touch'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Begin Test'));
    await tester.pumpAndSettle();
    final grid = tester.getRect(find.byKey(const ValueKey('touch-grid')));
    for (var row = 0; row < 10; row++) {
      final y = grid.top + (row + .5) * grid.height / 10;
      final drag = await tester.startGesture(Offset(grid.left + 1, y));
      await drag.moveTo(Offset(grid.right - 1, y));
      await drag.up();
    }
    await tester.pumpAndSettle();
    expect(store.status('touch'), TestStatus.passed);

    store.begin(null);
    await tester.pumpWidget(
      InspectionScope(
        notifier: store,
        child: MaterialApp(
          home: TouchTestView(
            key: const ValueKey('timeout-grid'),
            item: MockTestData.item('touch'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Begin Test'));
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(store.status('touch'), TestStatus.failed);
  });

  testWidgets(
    'multi-touch DONE and FAILED buttons record the selected result',
    (tester) async {
      final store = InspectionStore();
      addTearDown(store.dispose);
      store.begin(null);
      await tester.pumpWidget(
        InspectionScope(
          notifier: store,
          child: MaterialApp(
            home: MultiTouchView(item: MockTestData.item('multi')),
          ),
        ),
      );
      await tester.tap(find.text('Begin Test'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();
      expect(store.status('multi'), TestStatus.passed);

      store.begin(null);
      await tester.pumpWidget(
        InspectionScope(
          notifier: store,
          child: MaterialApp(
            home: MultiTouchView(
              key: const ValueKey('failed-multi-touch'),
              item: MockTestData.item('multi'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Begin Test'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('FAILED'));
      await tester.pumpAndSettle();
      expect(store.status('multi'), TestStatus.failed);
    },
  );

  test('a session keeps one result per catalog check and serializes it for reports', () {
    final store = InspectionStore();
    store.begin(null);
    store.setStatus(
      'touch',
      TestStatus.attention,
      measured: {'Coverage (%)': 83},
    );
    final report = store.current;
    expect(
      report.results.length,
      MockTestData.categories.expand((c) => c.items).length,
    );
    expect(report.details['touch']?.measured['Coverage (%)'], 83);
    expect(report.count(TestStatus.attention), 1);
    store.dispose();
  });
}
