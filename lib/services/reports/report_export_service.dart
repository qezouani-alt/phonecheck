import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../models/inspection_report.dart';
import '../../models/test_item.dart';

class ReportExportService {
  const ReportExportService();

  static const _channel = MethodChannel('com.phonecheck/reports');
  static const appStoreUrl = 'https://apps.apple.com/app/id6816173367';
  static const privacyPolicyUrl =
      'https://phonecheck01.blogspot.com/2026/09/blog-post.html';
  static const _reviewUrl = '$appStoreUrl?action=write-review';

  static const _appShareText =
      'Check a used iPhone before you buy with PhoneCheck. Run guided hardware and physical inspections, then keep a clear report of the results.\n\nDownload PhoneCheck: $appStoreUrl';

  /// Uses the native share sheet. Storage capacity is deliberately excluded:
  /// this summary is designed for sharing, while the private local report keeps
  /// the complete snapshot captured at inspection time.
  Future<void> share(InspectionReport report) =>
      _channel.invokeMethod<void>('share', {'text': summary(report)});

  Future<void> shareApp() =>
      _channel.invokeMethod<void>('share', {'text': _appShareText});

  Future<void> rateApp() =>
      _channel.invokeMethod<void>('openUrl', {'url': _reviewUrl});

  Future<void> openPrivacyPolicy() => openUrl(privacyPolicyUrl);

  Future<void> openUrl(String url) =>
      _channel.invokeMethod<void>('openUrl', {'url': url});

  String summary(InspectionReport report) {
    final lines = <String>[
      'PhoneCheck — iPhone Inspection Report',
      report.device,
      if (report.deviceSnapshot?.hardwareIdentifier != null)
        report.deviceSnapshot!.hardwareIdentifier!,
      if (report.deviceSnapshot?.osVersion != null)
        report.deviceSnapshot!.osVersion!,
      'Inspection: ${report.date.toLocal()}',
      '${report.count(TestStatus.passed)} passed · '
          '${report.count(TestStatus.attention)} need attention · '
          '${report.count(TestStatus.failed)} failed · '
          '${report.count(TestStatus.skipped)} skipped · '
          '${report.count(TestStatus.unavailable)} unavailable',
      '${report.passed} of ${report.completed} completed checks passed',
      AppConstants.disclaimer,
    ];
    return lines.join('\n');
  }
}
