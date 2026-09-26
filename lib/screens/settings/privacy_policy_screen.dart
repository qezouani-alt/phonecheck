import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_shell.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) => AppShell(
    title: 'Privacy Policy',
    child: PageContent(
      children: [
        const Text('Privacy & Legal', style: AppTextStyles.largeTitle),
        const SizedBox(height: 10),
        Text(
          'PhoneCheck is designed to help you record an inspection. It does not certify a device or guarantee its condition.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 22),
        const _PolicySection(
          title: 'Your inspection data',
          body: 'Inspection results and device details used in a report are kept on this device. You choose whether to share a report using the system share sheet.',
        ),
        const _PolicySection(
          title: 'Permissions',
          body: 'PhoneCheck requests access to features such as the camera, microphone, motion sensors, or location only when you start the related diagnostic.',
        ),
        const _PolicySection(
          title: 'Advertising',
          body: 'The app may display advertising from third-party advertising services. Those services may process information under their own privacy policies.',
        ),
        const _PolicySection(
          title: 'Contact',
          body: 'For questions about PhoneCheck, contact the developer through the app store listing.',
        ),
      ],
    ),
  );
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.cardTitle),
          const SizedBox(height: 7),
          Text(
            body,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    ),
  );
}
