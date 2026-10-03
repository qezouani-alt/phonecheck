import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'tracking_transparency_service.dart';

/// Loads an App Open Ad ahead of a foreground transition.
/// Uses the iOS app-open ad unit configured for this app.
class AppOpenAdService {
  static const _iosUnit = 'ca-app-pub-2535194044471316/5291308906';

  AppOpenAd? _ad;
  DateTime? _loadedAt;
  StreamSubscription<AppState>? _lifecycle;
  final Completer<void> _firstLoad = Completer<void>();
  Completer<void>? _showCompletion;
  bool _loading = false;
  bool _showing = false;
  bool _initialized = false;
  bool _returnedFromBackground = false;

  bool get _supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  bool get _available =>
      _ad != null &&
      _loadedAt != null &&
      DateTime.now().difference(_loadedAt!) < const Duration(hours: 4);

  Future<void> initialize() async {
    if (_initialized || !_supported) return;
    _initialized = true;
    try {
      if (!await TrackingTransparencyService.ensureResolved()) {
        if (!_firstLoad.isCompleted) _firstLoad.complete();
        return;
      }
      await MobileAds.instance.initialize();
      await AppStateEventNotifier.startListening();
      _lifecycle = AppStateEventNotifier.appStateStream.listen((state) {
        if (state == AppState.background) {
          _returnedFromBackground = true;
        } else if (state == AppState.foreground && _returnedFromBackground) {
          _returnedFromBackground = false;
          unawaited(showIfAvailable());
        }
      });
      unawaited(load());
    } catch (error) {
      debugPrint('App open ad initialization failed: $error');
      if (!_firstLoad.isCompleted) _firstLoad.complete();
      // Ads are optional. A missing test/plugin channel must never affect an
      // inspection or report flow.
    }
  }

  /// Gives the first ad a short chance to load while the splash is visible.
  /// Never present a late ad after the user has reached the home screen.
  Future<void> showOnLaunch() async {
    if (!_supported) return;
    try {
      await _firstLoad.future.timeout(const Duration(seconds: 5));
    } on TimeoutException {
      return;
    }
    if (_showing || _available) await showIfAvailable();
  }

  Future<void> load() async {
    if (!_supported || _loading || _available) return;
    _loading = true;
    try {
      await AppOpenAd.load(
        adUnitId: _iosUnit,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _ad?.dispose();
            _ad = ad;
            _loadedAt = DateTime.now();
            _loading = false;
            if (!_firstLoad.isCompleted) _firstLoad.complete();
          },
          onAdFailedToLoad: (error) {
            _loading = false;
            debugPrint('App open ad failed to load: $error');
            if (!_firstLoad.isCompleted) _firstLoad.complete();
          },
        ),
      );
    } catch (error) {
      _loading = false;
      debugPrint('App open ad request failed: $error');
      if (!_firstLoad.isCompleted) _firstLoad.complete();
    }
  }

  Future<void> showIfAvailable() async {
    if (_showing) return _showCompletion?.future;
    if (!_available) {
      unawaited(load());
      return;
    }
    final ad = _ad!;
    _ad = null;
    _loadedAt = null;
    _showing = true;
    final completion = _showCompletion = Completer<void>();
    void finish(AppOpenAd ad) {
      if (completion.isCompleted) return;
      _showing = false;
      _showCompletion = null;
      ad.dispose();
      completion.complete();
      unawaited(load());
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<AppOpenAd>(
      onAdDismissedFullScreenContent: finish,
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('App open ad failed to show: $error');
        finish(ad);
      },
    );
    try {
      await ad.show();
    } catch (error) {
      debugPrint('App open ad show request failed: $error');
      finish(ad);
    }
    await completion.future;
  }

  Future<void> dispose() async {
    if (!_firstLoad.isCompleted) _firstLoad.complete();
    if (_showCompletion case final completion?) {
      if (!completion.isCompleted) completion.complete();
    }
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
