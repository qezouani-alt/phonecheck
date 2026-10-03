import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/test_item.dart';
import 'fullscreen_diagnostic.dart';

class DisplayTestView extends StatefulWidget {
  const DisplayTestView({super.key, required this.item});
  final TestItem item;

  @override
  State<DisplayTestView> createState() => _DisplayTestViewState();
}

class _DisplayTestViewState extends State<DisplayTestView>
    with FullscreenDiagnosticMode<DisplayTestView> {
  int index = 0;
  bool active = false;
  bool _starting = false;
  bool _controlsOpen = false;

  bool get burnIn => widget.item.id == 'oled';
  List<(String, Color)> get samples => burnIn
      ? const [
          ('Black', Colors.black),
          ('Dark Gray', Color(0xFF242424)),
          ('Medium Gray', Color(0xFF808080)),
          ('White', Colors.white),
          ('Red', Colors.red),
          ('Green', Colors.green),
          ('Blue', Colors.blue),
        ]
      : const [
          ('White', Colors.white),
          ('Black', Colors.black),
          ('Red', Colors.red),
          ('Green', Colors.green),
          ('Blue', Colors.blue),
        ];

  void _begin() {
    if (_starting) return;
    _starting = true;
    unawaited(enterFullscreen());
    setState(() => active = true);
    _starting = false;
  }

  void _change(int delta) {
    final next = (index + delta).clamp(0, samples.length - 1);
    if (next == index) return;
    setState(() => index = next);
  }

  Future<void> _showControls() async {
    if (_controlsOpen || !mounted) return;
    _controlsOpen = true;
    final action = await showDiagnosticControls(
      context,
      title: widget.item.title,
      showReset: true,
    );
    _controlsOpen = false;
    if (!mounted) return;
    switch (action) {
      case DiagnosticControl.finish:
        await finishDiagnostic(widget.item);
      case DiagnosticControl.reset:
        setState(() => index = 0);
      case DiagnosticControl.cancel:
        cancelDiagnostic();
      case DiagnosticControl.resume || null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!active) {
      return DiagnosticIntro(
        item: widget.item,
        title: widget.item.title,
        icon: burnIn ? Icons.gradient_rounded : Icons.color_lens_outlined,
        instructions: burnIn
            ? 'Look for ghost images, uneven areas, permanent shapes, or color tinting.'
            : 'Look for dead or stuck pixels, unusual dots, and lines in every color.',
        note: 'Tap the right side for the next color or the left side to go back. Swipe left or right if you prefer. Long press anywhere for Finish or Cancel. The color fills every drawable area available to PhoneCheck; iOS may reserve system gesture regions and hardware cutouts.',
        onBegin: _begin,
      );
    }

    final (name, color) = samples[index];
    return fullscreenScaffold(
      backgroundColor: color,
      body: GestureDetector(
        key: const ValueKey('display-color-area'),
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          final width = MediaQuery.sizeOf(context).width;
          _change(details.localPosition.dx < width / 2 ? -1 : 1);
        },
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity.abs() > 100) _change(velocity < 0 ? 1 : -1);
        },
        onLongPress: _showControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const SizedBox.expand(),
            Positioned(
              left: 20,
              right: 20,
              bottom: 14,
              child: DiagnosticResultButtons(
                onDone: () => recordDiagnosticResult(
                  widget.item,
                  TestStatus.passed,
                  measured: {'Color shown at decision': name},
                ),
                onFailed: () => recordDiagnosticResult(
                  widget.item,
                  TestStatus.failed,
                  measured: {'Color shown at decision': name},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
