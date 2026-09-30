import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

enum TestStatus { pending, passed, attention, failed, skipped, unavailable }

extension TestStatusView on TestStatus {
  String get label => switch (this) {
    TestStatus.pending => 'Not Tested',
    TestStatus.passed => 'Passed',
    TestStatus.attention => 'Needs Attention',
    TestStatus.failed => 'Failed',
    TestStatus.skipped => 'Skipped',
    TestStatus.unavailable => 'Unavailable',
  };
  String get shortLabel => switch (this) {
    TestStatus.pending => 'Pending',
    TestStatus.passed => 'Pass',
    TestStatus.attention => 'Attention',
    TestStatus.failed => 'Fail',
    TestStatus.skipped => 'Skipped',
    TestStatus.unavailable => 'Unavailable',
  };
  IconData get icon => switch (this) {
    TestStatus.pending => Icons.remove_circle_outline_rounded,
    TestStatus.passed => Icons.check_circle_rounded,
    TestStatus.attention => Icons.error_rounded,
    TestStatus.failed => Icons.cancel_rounded,
    TestStatus.skipped => Icons.skip_next_rounded,
    TestStatus.unavailable => Icons.block_rounded,
  };
  Color get color => switch (this) {
    TestStatus.pending => AppColors.gray,
    TestStatus.passed => AppColors.green,
    TestStatus.attention => AppColors.amber,
    TestStatus.failed => AppColors.red,
    TestStatus.skipped || TestStatus.unavailable => AppColors.gray,
  };
  bool get assessed =>
      this == TestStatus.passed ||
      this == TestStatus.attention ||
      this == TestStatus.failed;
}

TestStatus categoryStatus(Iterable<TestStatus> values) {
  final statuses = values.toList();
  if (statuses.contains(TestStatus.failed)) return TestStatus.failed;
  if (statuses.contains(TestStatus.attention)) return TestStatus.attention;
  if (statuses.contains(TestStatus.pending)) return TestStatus.pending;
  if (statuses.any((s) => s == TestStatus.passed)) return TestStatus.passed;
  if (statuses.contains(TestStatus.unavailable)) return TestStatus.unavailable;
  if (statuses.contains(TestStatus.skipped)) return TestStatus.skipped;
  return TestStatus.pending;
}

class TestItem {
  const TestItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
  final String id;
  final String title;
  final String description;
  final IconData icon;
}
