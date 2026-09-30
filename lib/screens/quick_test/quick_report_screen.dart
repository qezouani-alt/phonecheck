import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/mock_test_data.dart';
import '../../main.dart';
import '../../models/inspection_report.dart';
import '../../models/device/device_report_snapshot.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/inspection_summary_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/result_row.dart';
import '../reports/report_details_screen.dart';

class QuickReportScreen extends StatelessWidget {
  const QuickReportScreen({super.key, required this.ids});
  final List<String> ids;
  @override
  Widget build(BuildContext context) {
    final store = InspectionScope.of(context);
    final deviceInfo = DeviceInfoScope.of(context).info;
    final snapshot = deviceInfo == null
        ? null
        : DeviceReportSnapshot.fromInfo(deviceInfo);
    final report = InspectionReport(
      device: snapshot?.model ?? 'iPhone',
      deviceSnapshot: snapshot,
      date: DateTime.now(),
      results: {for (final id in ids) id: store.status(id)},
    );
    return AppShell(
      title: 'Quick Inspection Results',
      footer: PrimaryButton(
        label: 'Done',
        onPressed: () => Navigator.pop(context),
      ),
      child: PageContent(
        children: [
          const Text(
            'Quick Inspection Results',
            style: AppTextStyles.largeTitle,
          ),
          const SizedBox(height: 8),
          Text(
            'Results from the eight essential checks.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          InspectionSummaryCard(report: report),
          const SizedBox(height: 20),
          SoftCard(
            child: Column(
              children: [
                for (final id in ids)
                  ResultRow(
                    title: MockTestData.item(id).title,
                    status: store.status(id),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Preview Report',
            secondary: true,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReportDetailsScreen(report: report),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            AppConstants.disclaimer,
            style: AppTextStyles.secondary.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
