import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/purchase_recommendation.dart';
import 'app_shell.dart';
import 'primary_button.dart';

class PurchaseRecommendationCard extends StatelessWidget {
  const PurchaseRecommendationCard({
    super.key,
    required this.recommendation,
    required this.onViewIssues,
    required this.onRunAgain,
  });

  final PurchaseRecommendation recommendation;
  final VoidCallback onViewIssues;
  final VoidCallback onRunAgain;

  @override
  Widget build(BuildContext context) {
    final presentation = _RecommendationPresentation.from(recommendation.state);
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Purchase Recommendation',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: .2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: presentation.color.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: presentation.color.withValues(alpha: .22),
                  ),
                ),
                child: Icon(presentation.icon, color: presentation.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.title,
                      style: TextStyle(
                        color: presentation.color,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recommendation.message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _ResultCount(
                value: recommendation.passed,
                label: 'Passed',
                color: AppColors.green,
              ),
              _ResultCount(
                value: recommendation.attention,
                label: 'Needs Attention',
                color: AppColors.amber,
              ),
              _ResultCount(
                value: recommendation.failed,
                label: 'Failed',
                color: AppColors.red,
              ),
            ],
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'View Issues',
            icon: Icons.list_alt_rounded,
            secondary: true,
            onPressed: onViewIssues,
          ),
          const SizedBox(height: 8),
          PrimaryButton(
            label: 'Run Test Again',
            icon: Icons.refresh_rounded,
            onPressed: onRunAgain,
          ),
        ],
      ),
    );
  }
}

class _ResultCount extends StatelessWidget {
  const _ResultCount({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        '$value $label',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    ],
  );
}

class _RecommendationPresentation {
  const _RecommendationPresentation({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  factory _RecommendationPresentation.from(
    PurchaseRecommendationState state,
  ) => switch (state) {
    PurchaseRecommendationState.looksGood => const _RecommendationPresentation(
      color: AppColors.green,
      icon: Icons.check_circle_rounded,
    ),
    PurchaseRecommendationState.review => const _RecommendationPresentation(
      color: AppColors.amber,
      icon: Icons.error_rounded,
    ),
    PurchaseRecommendationState.majorIssues =>
      const _RecommendationPresentation(
        color: AppColors.red,
        icon: Icons.cancel_rounded,
      ),
    PurchaseRecommendationState.incomplete => const _RecommendationPresentation(
      color: AppColors.gray,
      icon: Icons.pending_actions_rounded,
    ),
  };
}
