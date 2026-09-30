import 'inspection_report.dart';
import 'test_item.dart';

enum PurchaseRecommendationState { looksGood, review, majorIssues, incomplete }

class PurchaseRecommendation {
  const PurchaseRecommendation({
    required this.state,
    required this.passed,
    required this.attention,
    required this.failed,
  });

  static const criticalTestIds = <String>{
    'touch',
    'multi',
    'pixel',
    'oled',
    'brightness',
    'speaker',
    'microphone',
    'front_camera',
    'rear_camera',
    'face_id',
    'charging_port',
    'cellular',
  };

  final PurchaseRecommendationState state;
  final int passed;
  final int attention;
  final int failed;

  String get title => switch (state) {
    PurchaseRecommendationState.looksGood => 'Looks Good to Buy',
    PurchaseRecommendationState.review => 'Check Before Buying',
    PurchaseRecommendationState.majorIssues => 'Major Issues Found',
    PurchaseRecommendationState.incomplete => 'Inspection Incomplete',
  };

  String get message => switch (state) {
    PurchaseRecommendationState.looksGood =>
      'No major issues were found in the tests performed.',
    PurchaseRecommendationState.review =>
      'Some items need attention. Review them before paying.',
    PurchaseRecommendationState.majorIssues => 'This iPhone failed important tests. Consider avoiding it unless the issues are resolved.',
    PurchaseRecommendationState.incomplete => 'Complete the remaining important tests before making a purchase decision.',
  };

  factory PurchaseRecommendation.fromReport(InspectionReport report) {
    final failed = report.count(TestStatus.failed);
    final attention = report.count(TestStatus.attention);
    final incompleteCriticalTests = criticalTestIds.any((id) {
      final status = report.results[id];
      return status == null || !status.assessed;
    });
    final criticalNeedsAttention = criticalTestIds.any(
      (id) => report.results[id] == TestStatus.attention,
    );

    final state = failed > 0
        ? PurchaseRecommendationState.majorIssues
        : incompleteCriticalTests
        ? PurchaseRecommendationState.incomplete
        : criticalNeedsAttention || attention >= 2
        ? PurchaseRecommendationState.review
        : PurchaseRecommendationState.looksGood;

    return PurchaseRecommendation(
      state: state,
      passed: report.count(TestStatus.passed),
      attention: attention,
      failed: failed,
    );
  }
}
