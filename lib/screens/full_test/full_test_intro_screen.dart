import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../../data/mock_test_data.dart';
import '../../models/test_item.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/category_card.dart';
import '../../widgets/primary_button.dart';
import 'screen_tests_screen.dart';
import 'category_tests_screen.dart';
import '../../main.dart';

class FullTestIntroScreen extends StatelessWidget {
  const FullTestIntroScreen({super.key});
  @override
  Widget build(BuildContext context) => AppShell(
    title: 'Full Inspection',
    footer: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryButton(
          label: 'Start Inspection',
          onPressed: () => _open(context, const ScreenTestsScreen()),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    ),
    child: PageContent(
      children: [
        const SizedBox(height: 16),
        const Text(
          'A clear picture before you buy.',
          style: AppTextStyles.largeTitle,
        ),
        const SizedBox(height: 8),
        Text(
          'We’ll guide you through each important part of this iPhone.',
          style: AppTextStyles.body.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        for (final (index, category) in MockTestData.categories.indexed)
          CategoryCard(
            category: category,
            status: categoryStatus(
              category.items.map(
                (i) => InspectionScope.of(context).status(i.id),
              ),
            ),
            onTap: () => _open(
              context,
              index == 0
                  ? const ScreenTestsScreen()
                  : CategoryTestsScreen(index: index),
            ),
          ),
        const SizedBox(height: 5),
        const Row(
          children: [
            Icon(Icons.schedule_rounded, size: 19),
            SizedBox(width: 8),
            Expanded(child: Text('Estimated time: 5–8 minutes')),
          ],
        ),
      ],
    ),
  );

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}
