import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../../models/test_item.dart';
import '../../widgets/primary_button.dart';
import 'fullscreen_diagnostic.dart';

class BrightnessTestView extends StatefulWidget {
  const BrightnessTestView({super.key, required this.item});
  final TestItem item;

  @override
  State<BrightnessTestView> createState() => _BrightnessTestViewState();
}

class _BrightnessTestViewState extends State<BrightnessTestView>
    with FullscreenDiagnosticMode<BrightnessTestView> {
  double preview = .55;
  bool active = false;
  bool _starting = false;
  bool _controlsOpen = false;

  void _begin() {
    if (_starting) return;
    _starting = true;
    unawaited(enterFullscreen());
    setState(() => active = true);
    _starting = false;
  }

  Future<void> _showControls() async {
    if (_controlsOpen || !mounted) return;
    _controlsOpen = true;
    final action = await showModalBottomSheet<DiagnosticControl>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, updateSheet) => SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Brightness Check', style: AppTextStyles.section),
                  const SizedBox(height: 7),
                  const Text(
                    'This slider changes only the preview in PhoneCheck. Adjust the iPhone’s actual brightness in Control Center or Settings to check the display.',
                    style: AppTextStyles.secondary,
                  ),
                  const SizedBox(height: 14),
                  Text('Preview brightness ${(preview * 100).round()}%'),
                  Row(
                    children: [
                      const Icon(Icons.brightness_low_rounded, size: 20),
                      Expanded(
                        child: Slider(
                          value: preview,
                          onChanged: (value) {
                            setState(() => preview = value);
                            updateSheet(() {});
                          },
                        ),
                      ),
                      const Icon(Icons.brightness_high_rounded, size: 20),
                    ],
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Finish Test',
                    icon: Icons.check_rounded,
                    onPressed: () =>
                        Navigator.pop(sheetContext, DiagnosticControl.finish),
                  ),
                  const SizedBox(height: 8),
                  PrimaryButton(
                    label: 'Resume Test',
                    secondary: true,
                    onPressed: () =>
                        Navigator.pop(sheetContext, DiagnosticControl.resume),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(sheetContext, DiagnosticControl.cancel),
                    child: const Text('Cancel Test'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    _controlsOpen = false;
    if (!mounted) return;
    switch (action) {
      case DiagnosticControl.finish:
        await finishDiagnostic(widget.item);
      case DiagnosticControl.cancel:
        cancelDiagnostic();
      case DiagnosticControl.reset || DiagnosticControl.resume || null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!active) {
      return DiagnosticIntro(
        item: widget.item,
        title: 'Brightness Check',
        icon: Icons.wb_sunny_rounded,
        instructions: 'Adjust brightness and check whether the display changes smoothly and evenly.',
        note: 'Swipe up or down to change the full-screen PhoneCheck preview. Tap anywhere to reveal a slider and Finish/Cancel controls. The preview does not change system brightness; use Control Center or Settings for the actual screen check.',
        onBegin: _begin,
      );
    }

    final deep = Color.lerp(
      const Color(0xFF061126),
      const Color(0xFF4197F5),
      preview,
    )!;
    final light = Color.lerp(
      const Color(0xFF183252),
      const Color(0xFFF8FDFF),
      preview,
    )!;
    return fullscreenScaffold(
      backgroundColor: deep,
      body: GestureDetector(
        key: const ValueKey('brightness-surface'),
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (details) => setState(() {
          preview = (preview - details.delta.dy / 420).clamp(0.0, 1.0);
        }),
        onTap: _showControls,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [deep, light],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: Center(
                  child: Icon(
                    Icons.wb_sunny_rounded,
                    color: Colors.white.withValues(alpha: .42 + preview * .5),
                    size: 136,
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .48),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        'Preview ${(preview * 100).round()}%  ·  Tap for controls',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 14,
                child: DiagnosticResultButtons(
                  onDone: () => recordDiagnosticResult(
                    widget.item,
                    TestStatus.passed,
                    measured: {
                      'Preview brightness (%)': (preview * 100).round(),
                    },
                  ),
                  onFailed: () => recordDiagnosticResult(
                    widget.item,
                    TestStatus.failed,
                    measured: {
                      'Preview brightness (%)': (preview * 100).round(),
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
