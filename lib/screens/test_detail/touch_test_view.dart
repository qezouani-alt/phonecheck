import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../main.dart';
import '../../models/test_item.dart';
import '../../models/touch_grid_coverage.dart';
import 'fullscreen_diagnostic.dart';

class TouchTestView extends StatefulWidget {
  const TouchTestView({super.key, required this.item});
  final TestItem item;

  @override
  State<TouchTestView> createState() => _TouchTestViewState();
}

class _TouchTestViewState extends State<TouchTestView>
    with FullscreenDiagnosticMode<TouchTestView> {
  final TouchGridCoverage coverage = TouchGridCoverage();
  final Map<int, Offset> _lastPositions = {};
  late final TwoFingerHoldDetector _hold = TwoFingerHoldDetector(_showControls);
  bool active = false;
  bool _starting = false;
  bool _controlsOpen = false;
  bool _completed = false;
  bool _timedOut = false;
  bool _resultSelectionOpen = false;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timeout;

  void _begin() {
    if (_starting) return;
    _starting = true;
    unawaited(enterFullscreen());
    _startAttempt();
    setState(() => active = true);
    _starting = false;
  }

  void _startAttempt() {
    _timeout?.cancel();
    _stopwatch
      ..reset()
      ..start();
    _timeout = Timer(const Duration(seconds: 30), () {
      _timedOut = true;
      if (!_controlsOpen && !_resultSelectionOpen) {
        unawaited(_completeAutomatically(TestStatus.failed));
      }
    });
  }

  void _down(PointerDownEvent event, Size size) {
    _lastPositions[event.pointer] = event.localPosition;
    _hold.down(event);
    if (coverage.markSegment(event.localPosition, event.localPosition, size)) {
      _coverageChanged();
    }
  }

  void _move(PointerMoveEvent event, Size size) {
    final previous = _lastPositions[event.pointer] ?? event.localPosition;
    _lastPositions[event.pointer] = event.localPosition;
    _hold.move(event);
    if (coverage.markSegment(previous, event.localPosition, size)) {
      _coverageChanged();
    }
  }

  void _up(PointerEvent event) {
    _lastPositions.remove(event.pointer);
    _hold.up(event);
  }

  void _coverageChanged() {
    setState(() {});
    if (coverage.count == TouchGridCoverage.cellCount) {
      unawaited(_completeAutomatically(TestStatus.passed));
    }
  }

  Map<String, Object?> _measurements({bool timedOut = false}) => {
    'Coverage (%)': coverage.percent,
    'Cells touched': coverage.count,
    'Total cells': TouchGridCoverage.cellCount,
    'Duration (seconds)':
        (_stopwatch.elapsedMilliseconds / 100).roundToDouble() / 10,
    if (timedOut) 'Timed out': true,
  };

  Future<void> _completeAutomatically(TestStatus status) async {
    if (_completed || !mounted) return;
    _completed = true;
    _timeout?.cancel();
    _stopwatch.stop();
    InspectionScope.of(context).setStatus(
      widget.item.id,
      status,
      measured: _measurements(timedOut: status == TestStatus.failed),
    );
    await restoreSystemUi();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _showControls() async {
    if (_controlsOpen || !mounted) return;
    _controlsOpen = true;
    final action = await showDiagnosticControls(
      context,
      title: 'Touchscreen Grid Test',
      showReset: true,
    );
    _controlsOpen = false;
    _hold.reset();
    if (!mounted) return;
    if (_timedOut) {
      await _completeAutomatically(TestStatus.failed);
      return;
    }
    switch (action) {
      case DiagnosticControl.finish:
        _resultSelectionOpen = true;
        _timeout?.cancel();
        _stopwatch.stop();
        await finishDiagnostic(widget.item, measured: {..._measurements()});
        _resultSelectionOpen = false;
        if (mounted) _startAttempt();
      case DiagnosticControl.reset:
        coverage.reset();
        _timedOut = false;
        _startAttempt();
        setState(() {});
      case DiagnosticControl.cancel:
        cancelDiagnostic();
      case DiagnosticControl.resume || null:
        break;
    }
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _stopwatch.stop();
    _hold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!active) {
      return DiagnosticIntro(
        item: widget.item,
        title: 'Touchscreen Grid Test',
        icon: Icons.grid_on_rounded,
        instructions: 'Drag across the entire screen within 30 seconds. Reaching 100% coverage validates this test automatically. Use a two-finger long press for controls.',
        note: 'The grid uses the full touchable area available to PhoneCheck. iOS may reserve some edges and hardware cutouts for the system. If coverage is not complete after 30 seconds, the result is recorded as failed.',
        onBegin: _begin,
      );
    }

    return fullscreenScaffold(
      backgroundColor: const Color(0xFFDCE2EA),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return Stack(
            fit: StackFit.expand,
            children: [
              Listener(
                key: const ValueKey('touch-grid'),
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) => _down(event, size),
                onPointerMove: (event) => _move(event, size),
                onPointerUp: _up,
                onPointerCancel: _up,
                child: CustomPaint(
                  painter: _TouchGridPainter(coverage.touched),
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: _OverlayPill(
                      '${coverage.percent}% covered  ·  ${coverage.count} / ${TouchGridCoverage.cellCount}',
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 14,
                child: DiagnosticResultButtons(
                  onDone: () => _completeAutomatically(TestStatus.passed),
                  onFailed: () => _completeAutomatically(TestStatus.failed),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TouchGridPainter extends CustomPainter {
  const _TouchGridPainter(this.touched);
  final Set<int> touched;

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / TouchGridCoverage.side;
    final cellHeight = size.height / TouchGridCoverage.side;
    final paint = Paint();
    for (var row = 0; row < TouchGridCoverage.side; row++) {
      for (var col = 0; col < TouchGridCoverage.side; col++) {
        paint.color = touched.contains(row * TouchGridCoverage.side + col)
            ? AppColors.green
            : const Color(0xFFDCE2EA);
        canvas.drawRect(
          Rect.fromLTWH(
            col * cellWidth + 1,
            row * cellHeight + 1,
            cellWidth - 2,
            cellHeight - 2,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_TouchGridPainter oldDelegate) => true;
}

class MultiTouchView extends StatefulWidget {
  const MultiTouchView({super.key, required this.item});
  final TestItem item;

  @override
  State<MultiTouchView> createState() => _MultiTouchViewState();
}

class _MultiTouchViewState extends State<MultiTouchView>
    with FullscreenDiagnosticMode<MultiTouchView> {
  final Map<int, Offset> points = {};
  late final TwoFingerHoldDetector _hold = TwoFingerHoldDetector(_showControls);
  int maximum = 0;
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
    final action = await showDiagnosticControls(
      context,
      title: 'Multi-Touch Test',
      showReset: true,
    );
    _controlsOpen = false;
    _hold.reset();
    if (!mounted) return;
    switch (action) {
      case DiagnosticControl.finish:
        await finishDiagnostic(
          widget.item,
          measured: {'Maximum simultaneous touches': maximum},
        );
      case DiagnosticControl.reset:
        setState(() => maximum = points.length);
      case DiagnosticControl.cancel:
        cancelDiagnostic();
      case DiagnosticControl.resume || null:
        break;
    }
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!active) {
      return DiagnosticIntro(
        item: widget.item,
        title: 'Multi-Touch Test',
        icon: Icons.pan_tool_alt_rounded,
        instructions: 'Place several fingers on the screen and move them together. Tap DONE when every touch responds, or FAILED when a touch is missing or unreliable.',
        note: 'Markers follow actual Flutter pointer locations. The maximum count records simultaneous touches, not a claim about inaccessible system areas.',
        onBegin: _begin,
      );
    }

    return fullscreenScaffold(
      backgroundColor: const Color(0xFF0C1B31),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Listener(
            key: const ValueKey('multi-touch-area'),
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) {
              _hold.down(event);
              setState(() {
                points[event.pointer] = event.localPosition;
                maximum = math.max(maximum, points.length);
              });
            },
            onPointerMove: (event) {
              _hold.move(event);
              if (points.containsKey(event.pointer)) {
                setState(() => points[event.pointer] = event.localPosition);
              }
            },
            onPointerUp: (event) {
              _hold.up(event);
              setState(() => points.remove(event.pointer));
            },
            onPointerCancel: (event) {
              _hold.up(event);
              setState(() => points.remove(event.pointer));
            },
            child: const SizedBox.expand(),
          ),
          IgnorePointer(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 8,
                  left: 12,
                  right: 12,
                  child: Center(
                    child: _OverlayPill(
                      'Active Touches ${points.length}  ·  Maximum Simultaneous Touches Detected $maximum',
                    ),
                  ),
                ),
                for (final entry in points.entries)
                  Positioned(
                    left: entry.value.dx - 28,
                    top: entry.value.dy - 28,
                    child: Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color:
                            _markerColors[entry.key.abs() %
                                    _markerColors.length]
                                .withValues(alpha: .8),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        '${entry.key}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
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
                measured: {'Maximum simultaneous touches': maximum},
              ),
              onFailed: () => recordDiagnosticResult(
                widget.item,
                TestStatus.failed,
                measured: {'Maximum simultaneous touches': maximum},
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _markerColors = [
  Color(0xFF1768CE),
  Color(0xFF13A88A),
  Color(0xFFDB7D2C),
  Color(0xFF9A62D1),
  Color(0xFFE25979),
];

class _OverlayPill extends StatelessWidget {
  const _OverlayPill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 350),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .57),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
