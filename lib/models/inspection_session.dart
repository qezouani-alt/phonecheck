import 'dart:math';

import 'device/device_report_snapshot.dart';
import 'test_category.dart';
import 'test_item.dart';
import 'test_result.dart';

String newInspectionId() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${Random.secure().nextInt(0x7fffffff).toRadixString(36)}';

class InspectionSession {
  InspectionSession({
    required this.startedAt,
    required this.deviceInfoSnapshot,
    required this.categories,
    required Map<String, TestResult> results,
    String? id,
  }) : id = id ?? newInspectionId(),
       _results = Map.of(results);
  final String id;
  final DateTime startedAt;
  DateTime? completedAt;
  String? notes;
  final DeviceReportSnapshot? deviceInfoSnapshot;
  final List<TestCategory> categories;
  final Map<String, TestResult> _results;
  Map<String, TestResult> get results => Map.unmodifiable(_results);

  /// Compatibility view for callers interested in checks the user has addressed.
  /// The complete result set, including pending checks, remains in [results].
  Map<String, TestStatus> get testResults => {
    for (final r in _results.values)
      if (r.status != TestStatus.pending) r.id: r.status,
  };
  Iterable<TestItem> get tests => categories.expand((c) => c.items);
  void record(TestResult result) {
    _results[result.id] = result;
  }
}
