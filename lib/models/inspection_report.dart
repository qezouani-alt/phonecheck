import 'test_item.dart';
import 'test_result.dart';
import 'inspection_session.dart';
import 'device/device_report_snapshot.dart';

class InspectionReport {
  InspectionReport({
    required this.device,
    required this.date,
    required Map<String, TestStatus> results,
    this.deviceSnapshot,
    String? id,
    this.completedAt,
    this.notes,
    Map<String, TestResult> details = const {},
  }) : id = id ?? newInspectionId(),
       results = Map.unmodifiable(results),
       details = Map.unmodifiable(details);
  final String id, device;
  final DateTime date;
  final DateTime? completedAt;
  final String? notes;
  final Map<String, TestStatus> results;
  final Map<String, TestResult> details;
  final DeviceReportSnapshot? deviceSnapshot;
  int count(TestStatus status) =>
      results.values.where((v) => v == status).length;
  int get completed => results.values.where((v) => v.assessed).length;
  int get resolved => results.length - count(TestStatus.pending);
  int get passed => count(TestStatus.passed);
  Map<String, Object?> toJson() => {
    'version': 1,
    'id': id,
    'device': device,
    'date': date.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'notes': notes,
    'deviceSnapshot': deviceSnapshot?.toJson(),
    'results': results.map((k, v) => MapEntry(k, v.name)),
    'details': details.map((k, v) => MapEntry(k, v.toJson())),
    'summary': {for (final s in TestStatus.values) s.name: count(s)},
  };
  factory InspectionReport.fromJson(Map<String, dynamic> json) =>
      InspectionReport(
        id: json['id'] as String,
        device: json['device'] as String,
        date: DateTime.parse(json['date'] as String),
        completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
        notes: json['notes'] as String?,
        deviceSnapshot: json['deviceSnapshot'] == null
            ? null
            : DeviceReportSnapshot.fromJson(
                Map<String, dynamic>.from(json['deviceSnapshot'] as Map),
              ),
        results: (json['results'] as Map).map(
          (k, v) =>
              MapEntry(k as String, TestStatus.values.byName(v as String)),
        ),
        details: (json['details'] as Map? ?? {}).map(
          (k, v) => MapEntry(
            k as String,
            TestResult.fromJson(Map<String, dynamic>.from(v as Map)),
          ),
        ),
      );
}
