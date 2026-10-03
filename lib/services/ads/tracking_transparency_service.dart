import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Resolves iOS tracking authorization before any ad request is made.
class TrackingTransparencyService {
  static const _channel = MethodChannel('com.phonecheck/tracking');
  static Future<bool>? _pending;

  static Future<bool> ensureResolved() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return Future<bool>.value(true);
    }
    return _pending ??= _request().whenComplete(() => _pending = null);
  }

  static Future<bool> _request() async {
    try {
      final status = await _channel.invokeMethod<int>('requestAuthorization');
      // 0 means iOS has not obtained a choice; 1, 2 and 3 are resolved.
      return status == 1 || status == 2 || status == 3;
    } on PlatformException catch (error) {
      debugPrint('Tracking authorization request failed: $error');
      return false;
    } on MissingPluginException catch (error) {
      debugPrint('Tracking authorization channel unavailable: $error');
      return false;
    }
  }
}
