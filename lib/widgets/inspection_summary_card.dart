import 'package:flutter/material.dart';

import '../models/inspection_report.dart';
import '../models/test_item.dart';
import 'app_shell.dart';

class InspectionSummaryCard extends StatelessWidget {
  const InspectionSummaryCard({super.key, required this.report});
  final InspectionReport report;
  @override
  Widget build(BuildContext context) => SoftCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${report.passed} of ${report.completed} completed checks passed',
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Results describe the checks performed, not overall phone health.',
        ),
        const SizedBox(height: 16),
        ResultCounts(statuses: report.results.values),
        if (report.details.values.any((r) => r.simulated)) ...[
          const SizedBox(height: 12),
          const Text(
            'Includes developer simulator results. These are not hardware measurements.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ],
    ),
  );
}

class ResultCounts extends StatelessWidget {
  const ResultCounts({super.key, required this.statuses});
  final Iterable<TestStatus> statuses;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 14,
    runSpacing: 10,
    children: [
      for (final status in TestStatus.values)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, color: status.color, size: 18),
            const SizedBox(width: 5),
            Text(
              '${statuses.where((s) => s == status).length} ${status.shortLabel}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
    ],
  );
}
