import 'package:flutter/material.dart';

import '../../data/mock_test_data.dart';
import '../../main.dart';
import '../../models/test_item.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/diagnostic_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/physical_inspection_card.dart';
import '../../widgets/test_progress_header.dart';
import '../../widgets/inspection_summary_card.dart';
import '../test_detail/test_detail_screen.dart';
import '../result/inspection_complete_screen.dart';

class CategoryTestsScreen extends StatelessWidget {
  const CategoryTestsScreen({super.key, required this.index});
  final int index;
  @override
  Widget build(BuildContext context) {
    final category = MockTestData.categories[index];
    final store = InspectionScope.of(context);
    return AppShell(
      title: category.title,
      footer: PrimaryButton(
        label: 'Review Category',
        onPressed: () => _review(context),
      ),
      child: PageContent(
        children: [
          TestProgressHeader(
            index: index,
            title: category.title,
            count: category.items.length,
          ),
          const SizedBox(height: 20),
          if (index == 5)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Inspect each part and record Good, Attention or Problem. These are guided checks, not automatic hardware certification.',
              ),
            ),
          for (final item in category.items)
            if (index == 5)
              PhysicalInspectionCard(
                item: item,
                status: store.status(item.id),
                onChanged: (status) => store.setStatus(item.id, status),
                onOpen: item.id == 'face_id'
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TestDetailScreen(item: item),
                        ),
                      )
                    : null,
              )
            else
              DiagnosticCard(
                item: item,
                status: store.status(item.id),
                actionLabel: index == 1
                    ? store.status(item.id) == TestStatus.pending
                          ? 'Start'
                          : 'Retest'
                    : null,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TestDetailScreen(item: item),
                  ),
                ),
              ),
          const SizedBox(height: 12),
          ResultCounts(statuses: category.items.map((i) => store.status(i.id))),
        ],
      ),
    );
  }

  Future<void> _review(BuildContext context) async {
    final category = MockTestData.categories[index];
    final store = InspectionScope.of(context);
    final pending = category.items.any(
      (i) => store.status(i.id) == TestStatus.pending,
    );
    final proceed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pending
                    ? 'Some tests haven’t been completed.'
                    : '${category.title} Complete',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ResultCounts(
                statuses: category.items.map((i) => store.status(i.id)),
              ),
              const SizedBox(height: 16),
              for (final item in category.items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    store.status(item.id).icon,
                    color: store.status(item.id).color,
                  ),
                  title: Text(item.title),
                  subtitle: Text(store.status(item.id).label),
                  trailing: const Icon(Icons.refresh),
                  onTap: () async {
                    Navigator.pop(sheet, false);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TestDetailScreen(item: item),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: pending
                    ? 'Continue Anyway'
                    : index == 5
                    ? 'Complete Inspection'
                    : 'Continue to ${MockTestData.categories[index + 1].title}',
                onPressed: () => Navigator.pop(sheet, true),
              ),
              TextButton(
                onPressed: () => Navigator.pop(sheet, false),
                child: Text(pending ? 'Complete Tests' : 'Back to Tests'),
              ),
            ],
          ),
        ),
      ),
    );
    if (proceed != true || !context.mounted) return;
    if (index == 5) store.finish();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => index == 5
            ? const InspectionCompleteScreen()
            : CategoryTestsScreen(index: index + 1),
      ),
    );
  }
}
