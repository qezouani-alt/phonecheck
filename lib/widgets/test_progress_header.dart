import 'package:flutter/material.dart';

import '../main.dart';
import '../data/mock_test_data.dart';
import '../core/theme/app_text_styles.dart';

class TestProgressHeader extends StatelessWidget {
  const TestProgressHeader({
    super.key,
    required this.index,
    required this.title,
    required this.count,
  });
  final int index, count;
  final String title;
  @override
  Widget build(BuildContext context) {
    final store = InspectionScope.of(context);
    final report = store.current;
    final done = store.completed(MockTestData.categories[index].items);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${index + 1} of 6 categories', style: AppTextStyles.secondary),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: report.results.isEmpty
              ? 0
              : report.resolved / report.results.length,
          minHeight: 6,
          semanticsLabel: 'Inspection progress',
          semanticsValue: report.results.isEmpty
              ? '0%'
              : '${((report.resolved / report.results.length) * 100).round()}%',
        ),
        const SizedBox(height: 8),
        Text(
          '${report.resolved} of ${report.results.length} checks addressed overall',
        ),
        const SizedBox(height: 24),
        Text(
          title == 'Physical Inspection' ? title : '$title Tests',
          style: AppTextStyles.largeTitle,
        ),
        const SizedBox(height: 8),
        Text(
          '$done of $count addressed in this category · includes skipped and unavailable',
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: count == 0 ? 0 : done / count,
          semanticsLabel: 'Category progress',
        ),
      ],
    );
  }
}
