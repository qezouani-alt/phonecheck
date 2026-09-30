import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/mock_test_data.dart';
import '../../main.dart';
import '../../models/inspection_report.dart';
import '../../models/device/device_format.dart';
import '../../services/reports/report_export_service.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/info_row.dart';
import '../../widgets/inspection_summary_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/report_category_card.dart';

class ReportDetailsScreen extends StatelessWidget {
  const ReportDetailsScreen({super.key, required this.report});
  final InspectionReport report;
  @override
  Widget build(BuildContext context) => AppShell(
    title: 'Report Preview',
    footer: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                label: 'Share',
                icon: Icons.ios_share_rounded,
                onPressed: () async {
                  try {
                    await const ReportExportService().share(report);
                  } catch (_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sharing is unavailable right now.'),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PrimaryButton(
                label: 'Save',
                secondary: true,
                icon: Icons.bookmark_outline_rounded,
                onPressed: () async {
                  try {
                    await InspectionScope.of(context).saveReport(report);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Inspection saved.')),
                    );
                  } catch (_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not save this report.'),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    ),
    child: PageContent(
      children: [
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_user_rounded, size: 23),
                  SizedBox(width: 8),
                  Text(
                    'PhoneCheck',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'iPhone Inspection Report',
                style: AppTextStyles.section,
              ),
              const SizedBox(height: 12),
              InfoRow(label: 'Device', value: report.device),
              InfoRow(
                label: 'iOS',
                value: DeviceFormat.text(report.deviceSnapshot?.osVersion),
              ),
              if (report.deviceSnapshot != null) ...[
                InfoRow(
                  label: 'Hardware Identifier',
                  value: DeviceFormat.text(
                    report.deviceSnapshot?.hardwareIdentifier,
                  ),
                ),
                InfoRow(
                  label: 'Storage Capacity',
                  value: DeviceFormat.bytes(
                    report.deviceSnapshot?.storageTotalBytes,
                  ),
                ),
                InfoRow(
                  label: 'Storage Available at Inspection',
                  value: DeviceFormat.bytes(
                    report.deviceSnapshot?.storageAvailableBytes,
                  ),
                ),
                InfoRow(
                  label: 'Battery at Inspection',
                  value: DeviceFormat.percent(
                    report.deviceSnapshot?.batteryPercent,
                  ),
                ),
                InfoRow(
                  label: 'Native Display',
                  value:
                      report.deviceSnapshot?.nativeWidth == null ||
                          report.deviceSnapshot?.nativeHeight == null
                      ? 'Unavailable'
                      : '${report.deviceSnapshot!.nativeWidth} × ${report.deviceSnapshot!.nativeHeight} px',
                ),
                InfoRow(
                  label: 'Maximum Refresh Rate',
                  value: report.deviceSnapshot?.maximumRefreshRate == null
                      ? 'Unavailable'
                      : '${report.deviceSnapshot!.maximumRefreshRate} Hz',
                ),
                InfoRow(
                  label: 'Detected Cameras',
                  value: DeviceFormat.text(
                    report.deviceSnapshot?.cameraConfiguration,
                  ),
                ),
              ],
              InfoRow(
                label: 'Date',
                value:
                    '${_month(report.date.month)} ${report.date.day}, ${report.date.year}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        InspectionSummaryCard(report: report),
        const SizedBox(height: 22),
        const Text('Inspection results', style: AppTextStyles.section),
        const SizedBox(height: 12),
        for (final category in MockTestData.categories.where(
          (category) =>
              category.items.any((item) => report.results.containsKey(item.id)),
        ))
          ReportCategoryCard(category: category, report: report),
        const SizedBox(height: 8),
        Text(
          AppConstants.disclaimer,
          style: AppTextStyles.secondary.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
  static String _month(int month) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];
}
