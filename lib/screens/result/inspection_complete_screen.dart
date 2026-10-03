import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/primary_button.dart';
import 'final_report_screen.dart';

class InspectionCompleteScreen extends StatefulWidget {
  const InspectionCompleteScreen({super.key});
  @override
  State<InspectionCompleteScreen> createState() =>
      _InspectionCompleteScreenState();
}

class _InspectionCompleteScreenState extends State<InspectionCompleteScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  )..forward();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppShell(
    title: 'Inspection Complete',
    footer: PrimaryButton(
      label: 'View Report',
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FinalReportScreen()),
      ),
    ),
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: CurvedAnimation(
                parent: controller,
                curve: Curves.easeOutBack,
              ),
              child: Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.green.withValues(alpha: .12),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 86,
                  color: AppColors.green,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Inspection Complete',
              textAlign: TextAlign.center,
              style: AppTextStyles.largeTitle,
            ),
            const SizedBox(height: 9),
            Text(
              'Your test results are ready.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
