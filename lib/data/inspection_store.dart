import 'package:flutter/foundation.dart';

import '../models/device/device_report_snapshot.dart';
import '../models/device/phone_device_info.dart';
import '../models/inspection_report.dart';
import '../models/inspection_session.dart';
import '../models/test_item.dart';
import '../models/test_result.dart';
import '../services/reports/report_repository.dart';
import 'mock_test_data.dart';

class InspectionStore extends ChangeNotifier {
  InspectionStore({ReportRepository? repository})
    : repository = repository ?? LocalReportRepository();
  final ReportRepository repository;
  List<InspectionReport> _saved = [];
  InspectionSession? _session;
  Future<void>? _load;
  Future<void> _mutation = Future.value();
  bool loading = false;
  String? storageError;
  bool _disposed = false;
  InspectionSession? get session => _session;
  TestStatus status(String id) =>
      _session?.results[id]?.status ?? TestStatus.pending;
  void setStatus(
    String id,
    TestStatus status, {
    Map<String, Object?> measured = const {},
    String? note,
    bool simulated = false,
  }) {
    if (_session == null) begin(null);
    final item = MockTestData.item(id);
    final category = MockTestData.categories.firstWhere(
      (c) => c.items.any((i) => i.id == id),
    );
    _session!.record(
      TestResult(
        id: id,
        category: category.id,
        title: item.title,
        description: item.description,
        status: status,
        measured: measured,
        note: note,
        simulated: simulated,
        testedAt: status == TestStatus.pending ? null : DateTime.now(),
      ),
    );
    _notify();
  }

  void begin(PhoneDeviceInfo? deviceInfo) {
    _session = InspectionSession(
      startedAt: DateTime.now(),
      deviceInfoSnapshot: deviceInfo == null
          ? null
          : DeviceReportSnapshot.fromInfo(deviceInfo),
      categories: List.unmodifiable(MockTestData.categories),
      results: {
        for (final c in MockTestData.categories)
          for (final i in c.items)
            i.id: TestResult(
              id: i.id,
              category: c.id,
              title: i.title,
              description: i.description,
            ),
      },
    );
    _notify();
  }

  void finish() {
    _session?.completedAt = DateTime.now();
    _notify();
  }

  void setNotes(String value) {
    _session?.notes = value.trim().isEmpty ? null : value.trim();
    _notify();
  }

  void reset() {
    _session = null;
    _notify();
  }

  int completed(Iterable<TestItem> items) =>
      items.where((i) => status(i.id) != TestStatus.pending).length;
  InspectionReport get current => InspectionReport(
    id: _session?.id ?? 'not-started',
    device: _session?.deviceInfoSnapshot?.model ?? 'iPhone',
    date: _session?.startedAt ?? DateTime.now(),
    completedAt: _session?.completedAt,
    notes: _session?.notes,
    deviceSnapshot: _session?.deviceInfoSnapshot,
    details: _session?.results ?? {},
    results: {
      for (final i in MockTestData.categories.expand((c) => c.items))
        i.id: status(i.id),
    },
  );
  List<InspectionReport> get saved => List.unmodifiable(_saved);
  Future<void> loadReports() => _load ??= _read();
  Future<void> _read() async {
    loading = true;
    storageError = null;
    _notify();
    try {
      _saved = await repository.read();
    } catch (_) {
      storageError = 'Saved reports could not be loaded. Retry before saving or deleting reports.';
      rethrow;
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> retryLoad() {
    _load = null;
    return loadReports();
  }

  Future<void> save() => saveReport(current);
  Future<void> saveReport(InspectionReport report) =>
      _change(() => [report, ..._saved.where((r) => r.id != report.id)]);
  Future<void> delete(InspectionReport report) =>
      _change(() => _saved.where((r) => r.id != report.id).toList());
  Future<void> _change(List<InspectionReport> Function() next) {
    final task = _mutation.then((_) async {
      await loadReports();
      final updated = next();
      await repository.write(updated);
      _saved = updated;
      _notify();
    });
    _mutation = task.catchError((Object _) {});
    return task;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
