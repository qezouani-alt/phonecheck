import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../../data/mock_test_data.dart';
import '../../main.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/diagnostic_card.dart';
import '../../widgets/primary_button.dart';
import '../test_detail/test_detail_screen.dart';
import 'quick_report_screen.dart';

class QuickTestScreen extends StatefulWidget {
  const QuickTestScreen({super.key});
  @override
  State<QuickTestScreen> createState() => _QuickTestScreenState();
}

class _QuickTestScreenState extends State<QuickTestScreen> {
  bool started = false;
  static const ids = [
    'touch',
    'pixel',
    'speaker',
    'microphone',
    'rear_camera',
    'side_button',
    'face_id',
    'charging_port',
  ];
  @override
  Widget build(BuildContext context) {
    final items = ids.map(MockTestData.item).toList();
    final store = InspectionScope.of(context);
    return AppShell(
      title: 'Quick Inspection',
      footer: PrimaryButton(
        label: started ? 'View Quick Results' : 'Start Quick Inspection',
        onPressed: started
            ? () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => QuickReportScreen(ids: ids)),
              )
            : () => setState(() => started = true),
      ),
      child: PageContent(
        children: [
          const Text('Quick Inspection', style: AppTextStyles.largeTitle),
          const SizedBox(height: 8),
          Text(
            'Check the most important functions in about 2 minutes.',
            style: AppTextStyles.body.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          SoftCard(
            child: Row(
              children: [
                Icon(
                  Icons.bolt_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '8 essential checks',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${store.completed(items)} / 8',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (started) ...[
            for (final item in items)
              DiagnosticCard(
                item: item,
                status: store.status(item.id),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TestDetailScreen(item: item),
                  ),
                ),
              ),
          ] else ...[
            for (final item in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      color: Theme.of(context).colorScheme.primary,
                      size: 21,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      item.id == 'pixel'
                          ? 'Display'
                          : item.id == 'rear_camera'
                          ? 'Camera'
                          : item.id == 'side_button'
                          ? 'Buttons'
                          : item.id == 'charging_port'
                          ? 'Charging'
                          : item.title
                                .replaceAll(' Test', '')
                                .replaceAll(' Grid', ''),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
