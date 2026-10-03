import 'package:flutter_test/flutter_test.dart';

import 'package:checkiphone/models/inspection_report.dart';
import 'package:checkiphone/models/purchase_recommendation.dart';
import 'package:checkiphone/models/test_item.dart';

void main() {
  InspectionReport report(Map<String, TestStatus> results) => InspectionReport(
    device: 'iPhone',
    date: DateTime(2026),
    results: results,
  );

  test('a failed test produces the major issues recommendation', () {
    final recommendation = PurchaseRecommendation.fromReport(
      report({'touch': TestStatus.failed}),
    );

    expect(recommendation.state, PurchaseRecommendationState.majorIssues);
    expect(recommendation.failed, 1);
  });

  test('an incomplete critical test blocks a good-to-buy recommendation', () {
    final recommendation = PurchaseRecommendation.fromReport(
      report({'touch': TestStatus.skipped, 'speaker': TestStatus.passed}),
    );

    expect(recommendation.state, PurchaseRecommendationState.incomplete);
  });

  test('critical or multiple attention results need review', () {
    final allCriticalPassed = {
      for (final id in PurchaseRecommendation.criticalTestIds)
        id: TestStatus.passed,
    };

    expect(
      PurchaseRecommendation.fromReport(
        report({...allCriticalPassed, 'touch': TestStatus.attention}),
      ).state,
      PurchaseRecommendationState.review,
    );
    expect(
      PurchaseRecommendation.fromReport(
        report({
          ...allCriticalPassed,
          'focus': TestStatus.attention,
          'flash': TestStatus.attention,
        }),
      ).state,
      PurchaseRecommendationState.review,
    );
    expect(
      PurchaseRecommendation.fromReport(report(allCriticalPassed)).state,
      PurchaseRecommendationState.looksGood,
    );
  });
}
