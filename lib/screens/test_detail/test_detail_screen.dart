import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/test_item.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/result_selection_sheet.dart';
import 'touch_test_view.dart';
import 'display_test_view.dart';
import '../../data/mock_test_data.dart';
import '../diagnostics/hardware_test_screen.dart';
import '../diagnostics/biometric_test_screen.dart';
import '../diagnostics/manual_test_screen.dart';
import 'brightness_test_view.dart';

class TestDetailScreen extends StatelessWidget {
  const TestDetailScreen({super.key, required this.item});
  final TestItem item;
  @override
  Widget build(BuildContext context) {
    final view = switch (item.id) {
      'multi' => MultiTouchView(item: item),
      'touch' => TouchTestView(item: item),
      'brightness' => BrightnessTestView(item: item),
      'pixel' || 'oled' => DisplayTestView(item: item),
      'face_id' => BiometricTestScreen(item: item),
      _ =>
        MockTestData.categoryFor(item.id).id == 'physical'
            ? ManualTestScreen(item: item)
            : HardwareTestScreen(item: item),
    };
    return view;
  }
}

Future<void> completeTest(
  BuildContext context,
  TestItem item, {
  String? question,
  List<String>? labels,
}) async {
  String? note;
  final store = InspectionScope.of(context);
  final result = await showResultSelection(
    context,
    question: question ?? questionFor(item.id),
    labels: labels ?? labelsFor(item.id),
    onNote: (value) => note = value,
  );
  if (result != null && context.mounted) {
    store.setStatus(item.id, result, note: note);
    Navigator.pop(context);
  }
}

String questionFor(String id) => switch (id) {
  'touch' => 'How did the touchscreen respond?',
  'multi' => 'Did all touches respond correctly?',
  'pixel' => 'Did you notice any dead or stuck pixels?',
  'oled' => 'Did you notice visible burn-in or image retention?',
  'brightness' => 'Did brightness respond correctly?',
  'speaker' || 'earpiece' => 'How did it sound?',
  'microphone' => 'Could you hear your voice clearly?',
  'focus' => 'Did the camera focus correctly?',
  'haptics' => 'Did you feel the vibration?',
  _ => 'What did you observe?',
};

List<String>? labelsFor(String id) => switch (id) {
  'pixel' => ['No issues', 'Not sure', 'Yes'],
  'oled' => ['No', 'Not sure', 'Yes'],
  'brightness' => ['Yes', 'Inconsistent', 'No'],
  'speaker' => [
    'Clear',
    'Some distortion / low volume',
    'No sound / severe problem',
  ],
  'earpiece' => ['Clear', 'Quiet / distorted', 'No sound'],
  'microphone' => ['Clear', 'Weak / noisy', 'No / unusable audio'],
  'focus' => ['Focus works', 'Focus is inconsistent', 'Focus does not work'],
  'haptics' => ['Yes', 'Weak', 'No'],
  'accelerometer' ||
  'gyroscope' ||
  'compass' ||
  'proximity' => ['Sensor responding', 'Unstable', 'No response'],
  'wifi' ||
  'bluetooth' ||
  'gps' ||
  'cellular' => ['Working', 'Not sure', 'Not working'],
  _ => null,
};

class TestIntroNote extends StatelessWidget {
  const TestIntroNote({super.key, required this.item});
  final TestItem item;
  @override
  Widget build(BuildContext context) => SoftCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            item.description,
            style: const TextStyle(fontSize: 14, height: 1.45),
          ),
        ),
      ],
    ),
  );
}
