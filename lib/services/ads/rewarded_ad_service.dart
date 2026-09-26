import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Shows an opt-in rewarded ad and reports whether Google awarded the reward.
/// Uses the iOS rewarded ad unit configured for this app.
class RewardedAdService {
  RewardedAdService._();

  static final RewardedAdService instance = RewardedAdService._();
  static const _iosUnit = 'ca-app-pub-2535194044471316/8838923240';

  RewardedAd? _ad;
  DateTime? _loadedAt;
  Future<void>? _loading;
  bool _showing = false;

  bool get _supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  void _discardExpiredAd() {
    if (_ad == null || _loadedAt == null) return;
    if (DateTime.now().difference(_loadedAt!) < const Duration(hours: 1)) {
      return;
    }
    _ad!.dispose();
    _ad = null;
    _loadedAt = null;
  }

  /// Starts loading during splash; callers can reuse the same in-flight load.
  Future<void> preload() async {
    if (!_supported) return;
    _discardExpiredAd();
    if (_ad != null) return;
    final pending = _loading;
    if (pending != null) return pending;
    final load = _load();
    _loading = load;
    try {
      await load;
    } finally {
      if (identical(_loading, load)) _loading = null;
    }
  }

  Future<void> _load() async {
    final loadCompleter = Completer<RewardedAd?>();
    var loadTimedOut = false;
    try {
      await MobileAds.instance.initialize();
      await RewardedAd.load(
        adUnitId: _iosUnit,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (loadTimedOut) {
              ad.dispose();
              return;
            }
            if (!loadCompleter.isCompleted) loadCompleter.complete(ad);
          },
          onAdFailedToLoad: (error) {
            debugPrint('Rewarded ad failed to load: $error');
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
      if (ad == null) return;
      _ad = ad;
      _loadedAt = DateTime.now();
    } catch (error) {
      debugPrint('Rewarded ad request failed: $error');
    }
  }

  Future<bool> showRewardedAd() async {
    if (!_supported || _showing) return false;
    await preload();
    _discardExpiredAd();
    final ad = _ad;
    if (ad == null) return false;
    _ad = null;
    _loadedAt = null;
    _showing = true;

    final rewardCompleter = Completer<bool>();
    var earnedReward = false;
    void finish(RewardedAd ad, bool rewarded) {
      if (rewardCompleter.isCompleted) return;
      _showing = false;
      ad.dispose();
      rewardCompleter.complete(rewarded);
      unawaited(preload());
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (ad) => finish(ad, earnedReward),
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded ad failed to show: $error');
        finish(ad, false);
      },
    );
    try {
      await ad.show(
        onUserEarnedReward: (adWithoutView, rewardItem) {
          earnedReward = true;
        },
      );
    } catch (error) {
      debugPrint('Rewarded ad show request failed: $error');
      finish(ad, false);
    }
    return rewardCompleter.future;
  }
}
