import 'package:flutter/material.dart';

import '../app_shell.dart';

class DeviceInfoSection extends StatelessWidget {
  const DeviceInfoSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.expanded = false,
    this.note,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool expanded;
  final String? note;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: SoftCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        key: PageStorageKey(title),
        initiallyExpanded: expanded,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 17),
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        children: [
          Divider(color: Theme.of(context).dividerColor),
          ...children,
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                note!,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class DeviceInfoCheckRow extends StatelessWidget {
  const DeviceInfoCheckRow({
    super.key,
    required this.label,
    required this.status,
    required this.buttonLabel,
    required this.onCheck,
    this.checking = false,
  });
  final String label;
  final String status;
  final String buttonLabel;
  final VoidCallback onCheck;
  final bool checking;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              status,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: checking ? null : onCheck,
            child: Text(checking ? 'Checking…' : buttonLabel),
          ),
        ),
      ],
    ),
  );
}

class DeviceInfoChip extends StatelessWidget {
  const DeviceInfoChip({super.key, required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    ),
  );
}
