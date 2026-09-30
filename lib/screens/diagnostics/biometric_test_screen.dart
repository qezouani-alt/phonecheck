import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/test_item.dart';
import '../../services/device/device_info_service.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/primary_button.dart';

class BiometricTestScreen extends StatefulWidget {
  const BiometricTestScreen({super.key, required this.item});
  final TestItem item;

  @override
  State<BiometricTestScreen> createState() => _BiometricTestScreenState();
}

class _BiometricTestScreenState extends State<BiometricTestScreen> {
  final service = DeviceInfoService();
  bool busy = false;
  String? result;

  Future<void> _test() async {
    setState(() => busy = true);
    try {
      final response = await service.check('checkBiometrics');
      if (!mounted) return;
      result = response['status'] as String? ?? 'Unavailable';
      if (result == 'Authenticated') {
        InspectionScope.of(context).setStatus(
          widget.item.id,
          TestStatus.passed,
          measured: {'Authentication successful': true},
          note: 'Authentication succeeded during this inspection.',
        );
      }
      setState(() {});
    } on DeviceInfoUnavailable {
      if (mounted) setState(() => result = 'Unavailable');
    } catch (_) {
      if (mounted) setState(() => result = 'Unavailable');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _record(TestStatus status) {
    InspectionScope.of(context).setStatus(widget.item.id, status);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final success = result == 'Authenticated';
    final unavailable = {
      'Unavailable',
      'Not Enrolled',
      'Temporarily Locked',
    }.contains(result);
    return AppShell(
      title: 'Face ID / Touch ID',
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (success)
            PrimaryButton(
              label: 'Done',
              onPressed: () => Navigator.pop(context),
            )
          else if (unavailable) ...[
            PrimaryButton(label: 'Try Again', onPressed: busy ? null : _test),
            const SizedBox(height: 8),
            PrimaryButton(
              label: 'Mark Unavailable',
              secondary: true,
              onPressed: () => _record(TestStatus.unavailable),
            ),
          ] else
            PrimaryButton(
              label: 'Test Face ID / Touch ID',
              onPressed: busy ? null : _test,
            ),
          TextButton(
            onPressed: () => _record(TestStatus.skipped),
            child: const Text('Skip Test'),
          ),
        ],
      ),
      child: PageContent(
        children: [
          const SizedBox(height: 24),
          Icon(
            success ? Icons.verified_user_rounded : Icons.face_rounded,
            size: 78,
            color: success
                ? TestStatus.passed.color
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          const Text(
            'Face ID / Touch ID Check',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          const Text(
            'PhoneCheck can ask iOS to authenticate only when you choose this test. A successful check confirms authentication worked at this moment; it is not a complete hardware health diagnostic.',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          if (busy) ...[
            const SizedBox(height: 24),
            const LinearProgressIndicator(),
          ],
          if (result != null) ...[
            const SizedBox(height: 24),
            SoftCard(
              child: Text(
                success
                    ? 'Authentication succeeded during this inspection.'
                    : 'Biometric check: $result',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
