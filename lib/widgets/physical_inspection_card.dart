import 'package:flutter/material.dart';

import '../models/test_item.dart';
import 'app_shell.dart';

class PhysicalInspectionCard extends StatelessWidget {
  const PhysicalInspectionCard({
    super.key,
    required this.item,
    required this.status,
    required this.onChanged,
    this.onOpen,
  });

  final TestItem item;
  final TestStatus status;
  final ValueChanged<TestStatus> onChanged;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onOpen != null)
                TextButton(onPressed: onOpen, child: const Text('Test')),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            item.description,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final choice in const [
                (TestStatus.passed, 'Good'),
                (TestStatus.attention, 'Attention'),
                (TestStatus.failed, 'Problem'),
              ])
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: choice.$1 == TestStatus.failed ? 0 : 6,
                    ),
                    child: Semantics(
                      button: true,
                      selected: status == choice.$1,
                      label: '${item.title}: ${choice.$2}',
                      child: OutlinedButton(
                        onPressed: () => onChanged(choice.$1),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 42),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          foregroundColor: status == choice.$1
                              ? choice.$1.color
                              : Theme.of(context).colorScheme.onSurface,
                          side: BorderSide(
                            color: status == choice.$1
                                ? choice.$1.color
                                : Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Text(choice.$2, textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
