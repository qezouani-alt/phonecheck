import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../services/ads/rewarded_ad_service.dart';

Future<void> unlockTestWithRewardedAd(
  BuildContext context, {
  required String testName,
  required Future<void> Function() onUnlocked,
}) async {
  final watchAd = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.ondemand_video_rounded, color: AppColors.blue),
      title: Text('Unlock $testName'),
      content: Text(
        'Watch a short rewarded ad to unlock $testName and start its diagnostics. You can cancel without starting the test.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(dialogContext, true),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Watch Ad to Unlock'),
        ),
      ],
    ),
  );
  if (watchAd != true || !context.mounted) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text('Loading rewarded ad…')),
          ],
        ),
      ),
    ),
  );

  final rewarded = await RewardedAdService.instance.showRewardedAd();
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();

  if (!rewarded) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'The ad did not complete or no reward was received. Try again when an ad is available.',
        ),
      ),
    );
    return;
  }

  await onUnlocked();
}
