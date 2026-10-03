import 'package:flutter/material.dart';

import '../../models/test_item.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/primary_button.dart';
import '../test_detail/test_detail_screen.dart';

class ManualTestScreen extends StatelessWidget {
  const ManualTestScreen({super.key, required this.item});
  final TestItem item;
  @override
  Widget build(BuildContext context) => AppShell(
    title: item.title,
    child: PageContent(
      children: [
        const SizedBox(height: 24),
        Icon(item.icon, size: 80, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 24),
        Text(
          item.title,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        Text(
          item.description,
          style: const TextStyle(fontSize: 18, height: 1.5),
        ),
        const SizedBox(height: 18),
        const SoftCard(
          child: Text(
            'This is a manual inspection. Record only what you observed. Choose Skipped or Unavailable if you cannot perform the check.',
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Record Result',
          onPressed: () => completeTest(
            context,
            item,
            labels: const ['Good', 'Attention', 'Problem'],
          ),
        ),
      ],
    ),
  );
}
