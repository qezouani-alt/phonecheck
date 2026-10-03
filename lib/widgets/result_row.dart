import 'package:flutter/material.dart';

import '../models/test_item.dart';
import '../models/test_result.dart';
import 'status_badge.dart';

class ResultRow extends StatelessWidget {
  const ResultRow({
    super.key,
    required this.title,
    required this.status,
    this.result,
    this.onRetest,
  });
  final String title;
  final TestStatus status;
  final TestResult? result;
  final VoidCallback? onRetest;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            StatusBadge(status: status, compact: true),
            if (onRetest != null)
              TextButton(onPressed: onRetest, child: const Text('Retest')),
          ],
        ),
        if (result?.measured.isNotEmpty == true) ...[
          const SizedBox(height: 5),
          for (final entry in result!.measured.entries)
            Text(
              '${entry.key}: ${entry.value}',
              style: const TextStyle(fontSize: 12),
            ),
        ],
        if (result?.note != null) ...[
          const SizedBox(height: 4),
          Text('Note: ${result!.note}', style: const TextStyle(fontSize: 12)),
        ],
        if (result?.testedAt != null) ...[
          const SizedBox(height: 4),
          Text(
            'Tested ${TimeOfDay.fromDateTime(result!.testedAt!).format(context)}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (result?.simulated == true)
          const Text(
            'Simulated developer result',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
      ],
    ),
  );
}
