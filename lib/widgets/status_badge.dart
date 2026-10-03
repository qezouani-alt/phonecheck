import 'package:flutter/material.dart';

import '../models/test_item.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
    this.fullLabel = false,
  });
  final TestStatus status;
  final bool compact;
  final bool fullLabel;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 9 : 11,
      vertical: compact ? 5 : 7,
    ),
    decoration: BoxDecoration(
      color: status.color.withValues(alpha: .11),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: status.color.withValues(alpha: .20)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(status.icon, size: compact ? 14 : 16, color: status.color),
        const SizedBox(width: 5),
        Text(
          compact && !fullLabel ? status.shortLabel : status.label,
          style: TextStyle(
            color: status.color,
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
