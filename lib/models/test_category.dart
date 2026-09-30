import 'package:flutter/material.dart';

import 'test_item.dart';

class TestCategory {
  const TestCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.items,
  });
  final String id;
  final String title;
  final IconData icon;
  final List<TestItem> items;
}
