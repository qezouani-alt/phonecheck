import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/inspection_report.dart';

abstract class ReportRepository {
  Future<List<InspectionReport>> read();
  Future<void> write(List<InspectionReport> reports);
}

class LocalReportRepository implements ReportRepository {
  static const channel = MethodChannel('com.phonecheck/reports');
  @override
  Future<List<InspectionReport>> read() async {
    final raw = await channel.invokeMethod<String>('read');
    if (raw == null) {
      throw const FormatException('Report storage did not respond.');
    }
    return (jsonDecode(raw) as List)
        .map(
          (v) => InspectionReport.fromJson(Map<String, dynamic>.from(v as Map)),
        )
        .toList();
  }

  @override
  Future<void> write(List<InspectionReport> reports) async {
    await channel.invokeMethod<void>('write', {
      'json': jsonEncode(reports.map((r) => r.toJson()).toList()),
    });
  }
}
