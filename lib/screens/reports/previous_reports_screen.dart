import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../../main.dart';
import '../../models/inspection_report.dart';
import '../../models/test_item.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_badge.dart';
import '../full_test/full_test_intro_screen.dart';
import 'report_details_screen.dart';

class PreviousReportsScreen extends StatelessWidget {
  const PreviousReportsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = InspectionScope.of(context);
    final reports = store.saved;
    return AppShell(
      title: 'Previous Inspections',
      child: store.loading
          ? const Center(child: CircularProgressIndicator())
          : reports.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.description_outlined, size: 72),
                    const SizedBox(height: 15),
                    const Text(
                      'No Inspections Yet',
                      style: AppTextStyles.section,
                    ),
                    const SizedBox(height: 6),
                    const Text('Completed inspections will appear here.'),
                    const SizedBox(height: 22),
                    PrimaryButton(
                      label: 'Start Your First Test',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FullTestIntroScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : PageContent(
              children: [
                const Text(
                  'Previous Inspections',
                  style: AppTextStyles.largeTitle,
                ),
                const SizedBox(height: 7),
                Text(
                  'Review your saved inspection results.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 22),
                for (final report in reports)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 11),
                    child: Dismissible(
                      key: ObjectKey(report),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 25),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.delete_rounded,
                          color: Colors.white,
                        ),
                      ),
                      confirmDismiss: (_) => _confirmDelete(context, report),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportDetailsScreen(report: report),
                          ),
                        ),
                        child: SoftCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      report.device,
                                      style: AppTextStyles.cardTitle,
                                    ),
                                  ),
                                  StatusBadge(
                                    status: report.count(TestStatus.failed) > 0
                                        ? TestStatus.failed
                                        : report.count(TestStatus.attention) > 0
                                        ? TestStatus.attention
                                        : TestStatus.passed,
                                    compact: true,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${report.date.month}/${report.date.day}/${report.date.year} · ${TimeOfDay.fromDateTime(report.date).format(context)}',
                                style: AppTextStyles.secondary.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${report.count(TestStatus.passed)} Passed   ·   ${report.count(TestStatus.attention)} Attention   ·   ${report.count(TestStatus.failed)} Failed',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    InspectionReport report,
  ) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete inspection?'),
        content: const Text('This removes the saved report from this iPhone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (approved != true || !context.mounted) return false;
    try {
      await InspectionScope.of(context).delete(report);
      return true;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete the report. It is still saved.'),
          ),
        );
      }
      return false;
    }
  }
}
