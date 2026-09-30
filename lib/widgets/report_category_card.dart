import 'package:flutter/material.dart';

import '../models/inspection_report.dart';
import '../models/test_category.dart';
import '../models/test_item.dart';
import 'app_shell.dart';
import 'result_row.dart';
import 'status_badge.dart';

class ReportCategoryCard extends StatelessWidget {
  const ReportCategoryCard({
    super.key,
    required this.category,
    required this.report,
    this.onRetest,
  });
  final TestCategory category;
  final InspectionReport report;
  final void Function(TestItem)? onRetest;
  @override
  Widget build(BuildContext context) {
    final items = category.items
        .where((item) => report.results.containsKey(item.id))
        .toList();
    final statuses = items.map((item) => report.results[item.id]!).toList();
    final status = categoryStatus(statuses);
    final passed = statuses.where((value) => value == TestStatus.passed).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 3),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
          leading: Icon(category.icon, color: status.color),
          title: Text(
            category.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '$passed passed · ${statuses.where((s) => s == TestStatus.attention).length} attention · '
            '${statuses.where((s) => s == TestStatus.failed).length} failed · '
            '${statuses.where((s) => s == TestStatus.skipped).length} skipped',
          ),
          trailing: StatusBadge(status: status, compact: true),
          children: [
            Divider(color: Theme.of(context).dividerColor),
            for (final item in items)
              ResultRow(
                title: item.title,
                status: report.results[item.id] ?? TestStatus.pending,
                result: report.details[item.id],
                onRetest:
                    onRetest != null &&
                        (report.results[item.id] == TestStatus.attention ||
                            report.results[item.id] == TestStatus.failed)
                    ? () => onRetest!(item)
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}
