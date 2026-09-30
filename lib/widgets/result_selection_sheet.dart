import 'package:flutter/material.dart';

import '../models/test_item.dart';

Future<TestStatus?> showResultSelection(
  BuildContext context, {
  String question = 'How did it work?',
  List<String>? labels,
  ValueChanged<String>? onNote,
}) => showModalBottomSheet<TestStatus>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        22,
        8,
        22,
        22 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (onNote != null)
            TextField(
              onChanged: onNote,
              maxLength: 500,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Optional note',
                hintText: 'What did you observe?',
              ),
            ),
          for (final (index, status)
              in TestStatus.values
                  .where((s) => s != TestStatus.pending)
                  .indexed)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(status.icon, color: status.color),
              title: Text(
                index < 3 ? (labels?[index] ?? status.label) : status.label,
              ),
              onTap: () => Navigator.pop(context, status),
            ),
        ],
      ),
    ),
  ),
);
