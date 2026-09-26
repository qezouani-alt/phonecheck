import 'package:flutter/material.dart';

import '../models/test_category.dart';
import '../models/test_item.dart';
import 'app_shell.dart';
import 'status_badge.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.status,
    required this.onTap,
    this.trailing,
  });
  final TestCategory category;
  final TestStatus status;
  final VoidCallback onTap;
  final String? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: SoftCard(
        child: Row(
          children: [
            Icon(
              category.icon,
              color: Theme.of(context).colorScheme.primary,
              size: 26,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    trailing ??
                        '${category.items.length} ${category.id == 'physical' ? 'checks' : 'tests'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            StatusBadge(status: status, compact: true),
          ],
        ),
      ),
    ),
  );
}
