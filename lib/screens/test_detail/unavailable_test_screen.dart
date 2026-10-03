import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/test_item.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/primary_button.dart';

class UnavailableTestScreen extends StatelessWidget {
  const UnavailableTestScreen({super.key, required this.item});
  final TestItem item;
  @override
  Widget build(BuildContext context) {
    final camera = [
      'front_camera',
      'rear_camera',
      'focus',
      'flash',
    ].contains(item.id);
    final microphone = item.id == 'microphone';
    final sensor = [
      'accelerometer',
      'gyroscope',
      'compass',
      'proximity',
      'haptics',
    ].contains(item.id);
    final title = camera
        ? 'Camera Access Needed'
        : microphone
        ? 'Microphone Access Needed'
        : sensor
        ? 'Sensor Unavailable'
        : 'Test Unavailable';
    final message = camera
        ? 'PhoneCheck needs camera access to perform this test.'
        : microphone
        ? 'PhoneCheck needs microphone access to record a sample.'
        : sensor
        ? 'This sensor could not be read for this test.'
        : 'This check is unavailable right now.';
    return AppShell(
      title: title,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: camera
                ? 'Allow Camera Access'
                : microphone
                ? 'Allow Microphone Access'
                : 'Try Again',
            onPressed: () {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('This action is simulated in the UI demo.'),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          PrimaryButton(
            label: 'Skip Test',
            secondary: true,
            onPressed: () {
              final navigator = Navigator.of(context);
              navigator.pop();
              navigator.pop();
            },
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: .11),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  sensor
                      ? Icons.sensors_off_rounded
                      : Icons.lock_outline_rounded,
                  color: AppColors.amber,
                  size: 52,
                ),
              ),
              const SizedBox(height: 25),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.section,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
