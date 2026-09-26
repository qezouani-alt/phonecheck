import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Loads an App Open Ad ahead of a foreground transition.
///
/// Test IDs are intentionally the defaults. Supply production IDs with
/// `--dart-define=ADMOB_IOS_APP_OPEN_AD_UNIT_ID=...` and its Android
/// equivalent before publishing.
class AppOpenAdService {
  static const _iosTestUnit = 'ca-app-pub-3940256099942544/5575463023';
  static const _androidTestUnit = 'ca-app-pub-3940256099942544/9257395921';
  static const _iosUnit = String.fromEnvironment(
    'ADMOB_IOS_APP_OPEN_AD_UNIT_ID',
    defaultValue: _iosTestUnit,
  );
  static const _androidUnit = String.fromEnvironment(
    'ADMOB_ANDROID_APP_OPEN_AD_UNIT_ID',
    defaultValue: _androidTestUnit,
  );

  AppOpenAd? _ad;
  DateTime? _loadedAt;
  StreamSubscription<AppState>? _lifecycle;
  bool _loading = false;
  bool _showing = false;
  bool _initialized = false;
  bool _returnedFromBackground = false;

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);
  String get _adUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS ? _iosUnit : _androidUnit;
  bool get _available =>
      _ad != null &&
      _loadedAt != null &&
      DateTime.now().difference(_loadedAt!) < const Duration(hours: 4);

  Future<void> initialize() async {
    if (_initialized || !_supported) return;
    _initialized = true;
    try {
      await MobileAds.instance.initialize();
      await AppStateEventNotifier.startListening();
      _lifecycle = AppStateEventNotifier.appStateStream.listen((state) {
        if (state == AppState.background) {
          _returnedFromBackground = true;
        } else if (state == AppState.foreground && _returnedFromBackground) {
          _returnedFromBackground = false;
          showIfAvailable();
        }
      });
      unawaited(load());
    } catch (_) {
      // Ads are optional. A missing test/plugin channel must never affect an
      // inspection or report flow.
    }
  }

  Future<void> load() async {
    if (!_supported || _loading || _available) return;
    _loading = true;
    try {
      await AppOpenAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _ad?.dispose();
            _ad = ad;
            _loadedAt = DateTime.now();
            _loading = false;
          },
          onAdFailedToLoad: (_) => _loading = false,
        ),
      );
    } catch (_) {
      _loading = false;
    }
  }

  void showIfAvailable() {
    if (!_available) {
      unawaited(load());
      return;
    }
    if (_showing) return;
    final ad = _ad!;
    _ad = null;
    _loadedAt = null;
    _showing = true;
    ad.fullScreenContentCallback = FullScreenContentCallback<AppOpenAd>(
      onAdDismissedFullScreenContent: (ad) {
        _showing = false;
        ad.dispose();
        unawaited(load());
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        _showing = false;
        ad.dispose();
        unawaited(load());
      },
    );
    ad.show();
  }

  Future<void> dispose() async {
    await _lifecycle?.cancel();
    _lifecycle = null;
    _ad?.dispose();
    _ad = null;
    if (_initialized && _supported) {
      try {
        await AppStateEventNotifier.stopListening();
      } catch (_) {}
    }
  }
}
