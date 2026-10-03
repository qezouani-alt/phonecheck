import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../main.dart';
import '../../models/test_item.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/result_selection_sheet.dart';
import 'test_detail_screen.dart';

/// Keeps system UI changes ordered so a fast pop cannot re-hide a later route.
mixin FullscreenDiagnosticMode<T extends StatefulWidget> on State<T> {
  Future<void> _systemUiChange = Future<void>.value();
  bool _fullscreen = false;
  bool _recordingDirectResult = false;

  Future<void> _queueSystemUi(bool hide) {
    _systemUiChange = _systemUiChange.then((_) async {
      try {
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: hide ? const [] : SystemUiOverlay.values,
        );
      } catch (_) {
        // The route must remain dismissible if the platform ignores the mode.
      }
    });
    return _systemUiChange;
  }

  Future<void> enterFullscreen() {
    if (_fullscreen) return _systemUiChange;
    _fullscreen = true;
    return _queueSystemUi(true);
  }

  Future<void> restoreSystemUi() {
    if (!_fullscreen) return _systemUiChange;
    _fullscreen = false;
    return _queueSystemUi(false);
  }

  void cancelDiagnostic() {
    unawaited(restoreSystemUi());
    if (mounted) Navigator.pop(context);
  }

  Future<void> finishDiagnostic(
    TestItem item, {
    List<String>? labels,
    Map<String, Object?> measured = const {},
  }) async {
    String? note;
    final store = InspectionScope.of(context);
    final result = await showResultSelection(
      context,
      question: questionFor(item.id),
      labels: labels ?? labelsFor(item.id),
      onNote: (value) => note = value,
    );
    if (result == null || !mounted) return;
    store.setStatus(item.id, result, measured: measured, note: note);
    unawaited(restoreSystemUi());
    if (mounted) Navigator.pop(context);
  }

  Future<void> recordDiagnosticResult(
    TestItem item,
    TestStatus status, {
    Map<String, Object?> measured = const {},
  }) async {
    if (_recordingDirectResult || !mounted) return;
    _recordingDirectResult = true;
    InspectionScope.of(context).setStatus(item.id, status, measured: measured);
    await restoreSystemUi();
    if (mounted) Navigator.pop(context);
  }

  Widget fullscreenScaffold({required Widget body, Color? backgroundColor}) =>
      PopScope(
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) unawaited(restoreSystemUi());
        },
        child: Scaffold(backgroundColor: backgroundColor, body: body),
      );

  @override
  void dispose() {
    unawaited(restoreSystemUi());
    super.dispose();
  }
}

class DiagnosticResultButtons extends StatelessWidget {
  const DiagnosticResultButtons({
    super.key,
    required this.onDone,
    required this.onFailed,
  });

  final VoidCallback onDone;
  final VoidCallback onFailed;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: 'Done: record this test as passed',
            child: FilledButton(
              onPressed: onDone,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('DONE'),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Semantics(
            button: true,
            label: 'Failed: record this test as failed',
            child: FilledButton(
              onPressed: onFailed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('FAILED'),
            ),
          ),
        ),
      ],
    ),
  );
}

class DiagnosticIntro extends StatelessWidget {
  const DiagnosticIntro({
    super.key,
    required this.title,
    required this.item,
    required this.icon,
    required this.instructions,
    required this.onBegin,
    this.note,
  });

  final String title;
  final TestItem item;
  final IconData icon;
  final String instructions;
  final String? note;
  final VoidCallback onBegin;

  @override
  Widget build(BuildContext context) => AppShell(
    title: title,
    footer: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryButton(label: 'Begin Test', onPressed: onBegin),
        Wrap(
          children: [
            for (final status in [TestStatus.skipped, TestStatus.unavailable])
              TextButton(
                onPressed: () {
                  InspectionScope.of(context).setStatus(item.id, status);
                  Navigator.pop(context);
                },
                child: Text(status.label),
              ),
          ],
        ),
      ],
    ),
    child: PageContent(
      children: [
        const SizedBox(height: 12),
        Icon(icon, size: 76, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 25),
        Text(title, style: AppTextStyles.largeTitle),
        const SizedBox(height: 14),
        Text(instructions, style: AppTextStyles.body),
        if (note != null) ...[
          const SizedBox(height: 20),
          SoftCard(
            child: Text(
              note!,
              style: AppTextStyles.secondary.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class TwoFingerHoldDetector {
  TwoFingerHoldDetector(this.onHold);

  final VoidCallback onHold;
  final Map<int, Offset> _positions = {};
  Map<int, Offset>? _holdOrigins;
  Timer? _timer;
  bool _triggered = false;

  void down(PointerDownEvent event) {
    _positions[event.pointer] = event.localPosition;
    if (_positions.length == 2 && !_triggered) {
      _holdOrigins = Map.of(_positions);
      _timer = Timer(const Duration(milliseconds: 750), () {
        _timer = null;
        if (_positions.length < 2 || _holdOrigins == null) return;
        _triggered = true;
        _holdOrigins = null;
        onHold();
      });
    } else if (_positions.length > 2) {
      _cancelHold();
    }
  }

  void move(PointerMoveEvent event) {
    _positions[event.pointer] = event.localPosition;
    final origin = _holdOrigins?[event.pointer];
    if (origin != null && (origin - event.localPosition).distance > 18) {
      _cancelHold();
    }
  }

  void up(PointerEvent event) {
    _positions.remove(event.pointer);
    if (_positions.length < 2) _cancelHold();
    if (_positions.isEmpty) _triggered = false;
  }

  void _cancelHold() {
    _timer?.cancel();
    _timer = null;
    _holdOrigins = null;
  }

  void reset() {
    _cancelHold();
    _positions.clear();
    _triggered = false;
  }

  void dispose() => _cancelHold();
}

enum DiagnosticControl { resume, finish, reset, cancel }

Future<DiagnosticControl?> showDiagnosticControls(
  BuildContext context, {
  required String title,
  bool showReset = false,
}) => showModalBottomSheet<DiagnosticControl>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (sheetContext) => SafeArea(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.section),
            const SizedBox(height: 15),
            PrimaryButton(
              label: 'Finish Test',
              icon: Icons.check_rounded,
              onPressed: () =>
                  Navigator.pop(sheetContext, DiagnosticControl.finish),
            ),
            if (showReset) ...[
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Reset',
                secondary: true,
                icon: Icons.refresh_rounded,
                onPressed: () =>
                    Navigator.pop(sheetContext, DiagnosticControl.reset),
              ),
            ],
            const SizedBox(height: 8),
            PrimaryButton(
              label: 'Resume Test',
              secondary: true,
              icon: Icons.play_arrow_rounded,
              onPressed: () =>
                  Navigator.pop(sheetContext, DiagnosticControl.resume),
            ),
            const SizedBox(height: 8),
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
);
