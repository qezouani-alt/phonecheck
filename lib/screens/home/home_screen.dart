import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../main.dart';
import '../../models/device/device_format.dart';
import '../../models/purchase_recommendation.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/purchase_recommendation_card.dart';
import '../../widgets/rewarded_test_unlock.dart';
import '../full_test/full_test_intro_screen.dart';
import '../quick_test/quick_test_screen.dart';
import '../device_info/device_info_screen.dart';
import '../reports/previous_reports_screen.dart';
import '../result/final_report_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 860;
    final store = InspectionScope.of(context);
    final report = store.session?.completedAt == null ? null : store.current;
    return AppShell(
      title: '',
      leading: false,
      child: PageContent(
        padding: EdgeInsets.fromLTRB(20, compact ? 8 : 12, 20, 28),
        children: [
          _HomeBrand(
            onSettings: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          const _DetectedDeviceCard(),
          if (report != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: PurchaseRecommendationCard(
                recommendation: PurchaseRecommendation.fromReport(report),
                onViewIssues: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FinalReportScreen()),
                ),
                onRunAgain: () => _runInspectionAgain(context),
              ),
            ),
          SizedBox(height: compact ? 10 : 20),
          Text(
            'Buying a used iPhone?\nTest it before you pay.',
            style: AppTextStyles.largeTitle.copyWith(
              fontSize: compact ? 27 : 32,
              height: 1.12,
              letterSpacing: -.6,
            ),
          ),
          SizedBox(height: compact ? 12 : 22),
          Container(
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(27),
              border: Border.all(color: Colors.white.withValues(alpha: .34)),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1479E8),
                  Color(0xFF0863D2),
                  Color(0xFF06489F),
                ],
                stops: [0, .55, 1],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0759B9).withValues(alpha: .30),
                  blurRadius: 34,
                  offset: const Offset(0, 18),
                ),
                BoxShadow(
                  color: const Color(0xFF63B7FF).withValues(alpha: .12),
                  blurRadius: 16,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                children: [
                  Positioned(
                    right: -100,
                    top: -125,
                    child: Container(
                      width: 310,
                      height: 310,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: .19),
                            const Color(0xFF68C9FF).withValues(alpha: .08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -42,
                    bottom: -142,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .10),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(compact ? 18 : 23),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: compact ? 42 : 48,
                              height: compact ? 42 : 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .16),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .20),
                                ),
                              ),
                              child: Icon(
                                Icons.fact_check_rounded,
                                color: Colors.white,
                                size: compact ? 24 : 27,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'FULL INSPECTION',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: .88),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .13),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .18),
                                ),
                              ),
                              child: Text(
                                '5–8 MIN',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: .92),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: compact ? 13 : 18),
                        Text(
                          'Ready to inspect\nthis iPhone?',
                          style: TextStyle(
                            fontSize: compact ? 23 : 27,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.16,
                            letterSpacing: -.3,
                          ),
                        ),
                        SizedBox(height: compact ? 7 : 10),
                        Text(
                          'Run guided checks of the key hardware and physical components.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .88),
                            height: 1.35,
                            fontSize: compact ? 13 : 14,
                          ),
                        ),
                        SizedBox(height: compact ? 14 : 19),
                        SizedBox(
                          width: double.infinity,
                          height: compact ? 50 : 54,
                          child: FilledButton.icon(
                            onPressed: () => unlockTestWithRewardedAd(
                              context,
                              testName: 'Full Inspection',
                              onUnlocked: () => _openFullInspection(context),
                            ),
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: const Text('Start Full Inspection'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.blue,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: .65),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: compact ? 12 : 20),
          _HomeLink(
            icon: Icons.bolt_rounded,
            title: 'Quick Inspection',
            subtitle: 'Check the most important functions quickly.',
            onTap: () => unlockTestWithRewardedAd(
              context,
              testName: 'Quick Inspection',
              onUnlocked: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuickTestScreen()),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Theme.of(context).dividerColor.withValues(alpha: .8),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'MORE TOOLS',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: Theme.of(context).dividerColor.withValues(alpha: .8),
                  ),
                ),
              ],
            ),
          ),
          _HomeLink(
            icon: Icons.phone_iphone_rounded,
            title: 'Device Info',
            subtitle: 'View available system and device information.',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DeviceInfoScreen()),
            ),
          ),
          _HomeLink(
            icon: Icons.history_rounded,
            title: 'Previous Reports',
            subtitle: 'View saved inspection results.',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PreviousReportsScreen()),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AppConstants.shortDisclaimer,
            textAlign: TextAlign.center,
            style: AppTextStyles.secondary.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFullInspection(BuildContext context) async {
    final device = DeviceInfoScope.of(context);
    if (device.info == null) await device.load();
    if (!context.mounted) return;
    InspectionScope.of(context).begin(device.info);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FullTestIntroScreen()),
    );
  }

  Future<void> _runInspectionAgain(BuildContext context) async {
    await unlockTestWithRewardedAd(
      context,
      testName: 'Full Inspection',
      onUnlocked: () async {
        final device = DeviceInfoScope.of(context);
        InspectionScope.of(context).begin(device.info);
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FullTestIntroScreen()),
        );
      },
    );
  }
}

class _HomeBrand extends StatelessWidget {
  const _HomeBrand({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.blue,
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Icon(
          Icons.verified_user_rounded,
          color: Colors.white,
          size: 23,
        ),
      ),
      const SizedBox(width: 10),
      const Text(
        'PhoneCheck',
        style: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          letterSpacing: -.5,
        ),
      ),
      const Spacer(),
      IconButton(
        tooltip: 'Settings',
        onPressed: onSettings,
        icon: const Icon(Icons.settings_rounded),
        color: AppColors.blue,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: .50),
          side: BorderSide(color: Colors.white.withValues(alpha: .72)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    ],
  );
}

class _DetectedDeviceCard extends StatelessWidget {
  const _DetectedDeviceCard();

  @override
  Widget build(BuildContext context) {
    final controller = DeviceInfoScope.of(context);
    final detected = controller.info;
    final subtitle = detected == null
        ? controller.loading
              ? 'Detecting device…'
              : 'Device information unavailable'
        : '${detected.identity.text('systemName') ?? 'iOS'} ${detected.identity.text('osVersion') ?? ''} · '
              '${DeviceFormat.percent(detected.battery.integer('levelPercent'))} battery · '
              '${DeviceFormat.bytes(detected.storage.integer('availableBytes'))} available';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DeviceInfoScreen()),
      ),
      child: SoftCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: .11),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.blue.withValues(alpha: .10),
                ),
              ),
              child: const Icon(
                Icons.phone_iphone_rounded,
                color: AppColors.blue,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detected Device',
                    style: TextStyle(fontSize: 12, color: AppColors.gray),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detected?.identity.text('modelName') ?? 'iPhone',
                    style: AppTextStyles.cardTitle,
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.secondary.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _HomeLink extends StatelessWidget {
  const _HomeLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: SoftCard(
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.blue.withValues(alpha: .15),
                    AppColors.blue.withValues(alpha: .07),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: AppColors.blue.withValues(alpha: .12),
                ),
              ),
              child: Icon(icon, color: AppColors.blue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.cardTitle),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTextStyles.secondary.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}
