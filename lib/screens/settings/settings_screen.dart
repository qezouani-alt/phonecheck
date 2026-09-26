import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/reports/report_export_service.dart';
import '../../widgets/app_shell.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => AppShell(
    title: 'Settings',
    child: PageContent(
      children: [
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: AppColors.blue,
                  size: 29,
                ),
              ),
              const SizedBox(height: 16),
              const Text('PhoneCheck', style: AppTextStyles.section),
              const SizedBox(height: 7),
              Text(
                'PhoneCheck helps you inspect a used iPhone before you buy. Run guided checks, understand what needs attention, and keep a clear record of the tests performed.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Quick Actions', style: AppTextStyles.section),
        const SizedBox(height: 12),
        GlassSettingsAction(
          title: 'Share PhoneCheck',
          subtitle: 'Send the app to someone you know',
          icon: Icons.ios_share_rounded,
          tint: AppColors.blue,
          onPressed: () => _share(context),
        ),
        const SizedBox(height: 10),
        GlassSettingsAction(
          title: 'Privacy Policy',
          subtitle: 'How PhoneCheck handles your data',
          icon: Icons.privacy_tip_outlined,
          tint: const Color(0xFF7357C8),
          onPressed: () => _openPrivacyPolicy(context),
        ),
        const SizedBox(height: 10),
        GlassSettingsAction(
          title: 'Rate Us',
          subtitle: 'Tell us how PhoneCheck is working',
          icon: Icons.star_outline_rounded,
          tint: const Color(0xFFC57916),
          onPressed: () => _rate(context),
        ),
      ],
    ),
  );

  Future<void> _share(BuildContext context) async {
    try {
      await const ReportExportService().shareApp();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sharing is unavailable right now.')),
      );
    }
  }

  Future<void> _rate(BuildContext context) async {
    try {
      await const ReportExportService().rateApp();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Rating is unavailable right now. Please try again later.',
          ),
        ),
      );
    }
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    try {
      await const ReportExportService().openPrivacyPolicy();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Privacy Policy is unavailable right now.'),
        ),
      );
    }
  }
}

class GlassSettingsAction extends StatelessWidget {
  const GlassSettingsAction({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(22);
    return Semantics(
      button: true,
      label: title,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: dark
                  ? Colors.white.withValues(alpha: .085)
                  : Colors.white.withValues(alpha: .58),
              borderRadius: radius,
              border: Border.all(
                color: dark
                    ? Colors.white.withValues(alpha: .17)
                    : Colors.white.withValues(alpha: .78),
              ),
              boxShadow: [
                BoxShadow(
                  color: tint.withValues(alpha: dark ? .12 : .10),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              tint.withValues(alpha: .26),
                              tint.withValues(alpha: .10),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: tint.withValues(alpha: .22),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: tint.withValues(alpha: .15),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: tint, size: 23),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: tint.withValues(alpha: .10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: tint,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
