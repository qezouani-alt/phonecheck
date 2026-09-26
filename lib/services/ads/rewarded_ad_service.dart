import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Shows an opt-in rewarded ad and reports whether Google awarded the reward.
/// Test ad units are the defaults; provide production IDs with dart-defines.
class RewardedAdService {
  static const _iosTestUnit = 'ca-app-pub-3940256099942544/1712485313';
  static const _androidTestUnit = 'ca-app-pub-3940256099942544/5224354917';
  static const _iosUnit = String.fromEnvironment(
    'ADMOB_IOS_REWARDED_AD_UNIT_ID',
    defaultValue: _iosTestUnit,
  );
  static const _androidUnit = String.fromEnvironment(
    'ADMOB_ANDROID_REWARDED_AD_UNIT_ID',
    defaultValue: _androidTestUnit,
  );

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  String get _adUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS ? _iosUnit : _androidUnit;

  Future<bool> showRewardedAd() async {
    if (!_supported) return false;

    final loadCompleter = Completer<RewardedAd?>();
    var loadTimedOut = false;
    try {
      await MobileAds.instance.initialize();
      RewardedAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (loadTimedOut) {
              ad.dispose();
              return;
            }
            if (!loadCompleter.isCompleted) loadCompleter.complete(ad);
          },
          onAdFailedToLoad: (_) {
            if (!loadCompleter.isCompleted) loadCompleter.complete(null);
          },
        ),
      );
      final ad = await loadCompleter.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          loadTimedOut = true;
          return null;
        },
      );
      if (ad == null) return false;

      final rewardCompleter = Completer<bool>();
      var earnedReward = false;
      ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          if (!rewardCompleter.isCompleted) {
            rewardCompleter.complete(earnedReward);
          }
        },
        onAdFailedToShowFullScreenContent: (ad, _) {
          ad.dispose();
          if (!rewardCompleter.isCompleted) rewardCompleter.complete(false);
        },
      );
      ad.show(
        onUserEarnedReward: (adWithoutView, rewardItem) {
          earnedReward = true;
        },
      );
      return await rewardCompleter.future;
    } catch (_) {
      return false;
    }
  }
}
