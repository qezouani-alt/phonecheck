import 'package:flutter/material.dart';

class AdPlaceholderWidget extends StatelessWidget {
  const AdPlaceholderWidget({super.key});
  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    height: 58,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Theme.of(context).dividerColor),
    ),
    child: Text(
      'Sponsored space',
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}
