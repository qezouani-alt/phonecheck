import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/inspection_store.dart';
import '../../data/mock_test_data.dart';
import '../../main.dart';
import '../../models/inspection_report.dart';
import '../../models/test_item.dart';
import '../../services/reports/report_export_service.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/inspection_summary_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/report_category_card.dart';
import '../test_detail/test_detail_screen.dart';

class FinalReportScreen extends StatelessWidget {
  const FinalReportScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = InspectionScope.of(context);
    final report = store.current;
    return AppShell(
      title: 'Inspection Result',
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: 'Save Inspection',
            icon: Icons.bookmark_outline_rounded,
            onPressed: () async {
              try {
                await store.save();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Inspection saved to Previous Reports.'),
                  ),
                );
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Could not save this report. Existing reports were not changed.',
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Share Report',
                  secondary: true,
                  icon: Icons.ios_share_rounded,
                  onPressed: () => _share(context, report),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: PrimaryButton(
                  label: 'Retest Issues',
                  secondary: true,
                  icon: Icons.refresh_rounded,
                  onPressed: () => _chooseIssue(context, store),
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text('Back to Home'),
          ),
        ],
      ),
      child: PageContent(
        children: [
          const Text(
            'iPhone Inspection Result',
            style: AppTextStyles.largeTitle,
          ),
          const SizedBox(height: 8),
          Text(
            'A summary of the checks performed on this device.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          InspectionSummaryCard(report: report),
          const SizedBox(height: 23),
          const Text('Results by category', style: AppTextStyles.section),
          const SizedBox(height: 14),
          for (final category in MockTestData.categories)
            ReportCategoryCard(
              category: category,
              report: report,
              onRetest: (item) => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TestDetailScreen(item: item)),
              ),
            ),
          const SizedBox(height: 10),
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

  Future<void> _share(BuildContext context, InspectionReport report) async {
    try {
      await const ReportExportService().share(report);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sharing is unavailable right now. Your inspection is still available.',
          ),
        ),
      );
    }
  }

  Future<void> _chooseIssue(BuildContext context, InspectionStore store) async {
    final issues = MockTestData.categories
        .expand((category) => category.items)
        .where(
          (item) => [
            TestStatus.attention,
            TestStatus.failed,
          ].contains(store.status(item.id)),
        )
        .toList();
    if (issues.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No attention or failed checks to retest.'),
        ),
      );
      return;
    }
    final item = await showModalBottomSheet<TestItem>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'Retest Issues',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
            for (final issue in issues)
              ListTile(
                leading: Icon(
                  store.status(issue.id).icon,
                  color: store.status(issue.id).color,
                ),
                title: Text(issue.title),
                subtitle: Text(store.status(issue.id).label),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(sheetContext, issue),
              ),
          ],
        ),
      ),
    );
    if (item == null || !context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TestDetailScreen(item: item)),
    );
  }
}
