import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../../main.dart';
import '../../models/test_item.dart';
import '../../services/diagnostics/diagnostic_service.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/result_selection_sheet.dart';
import '../test_detail/test_detail_screen.dart';

class HardwareTestScreen extends StatefulWidget {
  const HardwareTestScreen({super.key, required this.item});
  final TestItem item;
  @override
  State<HardwareTestScreen> createState() => _HardwareTestScreenState();
}

class _HardwareTestScreenState extends State<HardwareTestScreen>
    with WidgetsBindingObserver {
  final service = DiagnosticService();
  Timer? timer;
  bool busy = false, ready = false, simulator = false, polling = false;
  String message = '', state = 'intro';
  Map<String, Object?> live = {}, measured = {};
  int generation = 0;
  String get id => widget.item.id;
  bool get camera =>
      ['front_camera', 'rear_camera', 'focus', 'flash'].contains(id);
  bool get audio => ['speaker', 'earpiece', 'microphone'].contains(id);
  bool get network => ['wifi', 'bluetooth', 'gps', 'cellular'].contains(id);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState value) {
    if (value == AppLifecycleState.paused ||
        value == AppLifecycleState.detached) {
      generation++;
      timer?.cancel();
      unawaited(service.stop());
      if (mounted) {
        setState(() {
          ready = false;
          busy = false;
          state = 'interrupted';
          message = 'Test interrupted. Begin again to resume.';
        });
      }
    }
  }

  @override
  void dispose() {
    generation++;
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(service.stop());
    super.dispose();
  }

  Future<void> begin() async {
    final token = ++generation;
    timer?.cancel();
    setState(() {
      busy = true;
      ready = false;
      message = id == 'gps' ? 'Waiting for location…' : 'Starting test…';
      live = {};
      measured = {};
    });
    try {
      final env = await service.call('environment');
      if (!mounted || token != generation) {
        return;
      }
      simulator = env['simulator'] == true;
      final response = simulator
          ? <String, Object?>{
              'status': 'unavailable',
              'message': 'Unavailable in Simulator',
            }
          : network
          ? await service.connectivity(id)
          : await service.call('start', {'id': id});
      if (!mounted || token != generation) {
        return;
      }
      setState(() {
        state = response['status'] as String? ?? 'unavailable';
        ready = state == 'ready';
        message = response['message'] as String? ?? 'Test unavailable.';
        busy = false;
        measured = Map<String, Object?>.from(
          response['measured'] as Map? ?? {},
        );
      });
      if (ready && !network) {
        await sample();
        timer = Timer.periodic(
          const Duration(milliseconds: 150),
          (_) => sample(),
        );
      }
    } catch (_) {
      if (mounted && token == generation) {
        setState(() {
          busy = false;
          state = 'unavailable';
          message = 'This test could not start. Retry, skip it, or record it as unavailable.';
        });
      }
    }
  }

  Future<void> sample() async {
    if (polling || !ready) return;
    polling = true;
    final token = generation;
    try {
      final values = await service.call('sample');
      if (!mounted || token != generation) {
        return;
      }
      setState(() {
        live = values;
        for (final entry in values.entries) {
          if (![
            'playing',
            'recording',
            'elapsed',
            'level',
            'error',
            'torch',
          ].contains(entry.key)) {
            measured[entry.key] = entry.value;
          }
        }
        if (values['error'] != null) {
          message = values['error'].toString();
          ready = false;
          state = 'unavailable';
          timer?.cancel();
          unawaited(service.stop());
        }
      });
    } catch (_) {
      if (mounted && token == generation) {
        setState(() {
          ready = false;
          state = 'unavailable';
          message = 'Live readings stopped. Begin again or skip this test.';
        });
        timer?.cancel();
        unawaited(service.stop());
      }
    } finally {
      polling = false;
    }
  }

  Future<void> action(String method) async {
    setState(() => busy = true);
    try {
      await service.action(method);
      await sample();
    } catch (_) {
      if (mounted) {
        setState(
          () => message = 'The action could not complete. Retry or mark this test unavailable.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> finish({bool simulated = false}) async {
    String? note;
    final store = InspectionScope.of(context);
    final status = await showResultSelection(
      context,
      question: simulated ? 'Developer simulator result' : questionFor(id),
      labels: labelsFor(id),
      onNote: (value) => note = value,
    );
    if (status == null || !mounted) {
      return;
    }
    store.setStatus(
      id,
      status,
      measured: simulated ? {} : Map.of(measured),
      note: note,
      simulated: simulated,
    );
    await service.stop();
    if (mounted) Navigator.pop(context);
  }

  void mark(TestStatus status) {
    InspectionScope.of(context).setStatus(
      id,
      status,
      measured: Map.of(measured),
      note: state == 'intro' ? null : message,
    );
    unawaited(service.stop());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final level = ((live['level'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0);
    final playing = live['playing'] == true;
    final recordingComplete = live['Recording completed'] == true;
    final angle = id == 'compass'
        ? (live['Magnetic heading (°)'] as num?)?.toDouble()
        : id == 'gyroscope'
        ? (live['Roll (°)'] as num?)?.toDouble()
        : ((live['X (g)'] as num?)?.toDouble() ?? 0) * 45;
    return AppShell(
      title: widget.item.title,
      child: PageContent(
        children: [
          Text(
            widget.item.title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            _instructions(id, widget.item.description),
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 20),
          if (camera && ready)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 320,
                child: UiKitView(
                  viewType: 'com.phonecheck/camera-preview',
                  gestureRecognizers: {
                    Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                    ),
                  },
                ),
              ),
            )
          else
            SoftCard(
              child: Column(
                children: [
                  if (audio && id != 'microphone')
                    _AudioWave(playing: playing)
                  else
                    Transform.rotate(
                      angle: (angle ?? 0) * math.pi / 180,
                      child: Icon(
                        widget.item.icon,
                        size: 88,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  if (id == 'microphone' && ready) ...[
                    const SizedBox(height: 18),
                    LinearProgressIndicator(
                      value: level,
                      semanticsLabel: 'Microphone activity',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${((live['elapsed'] as num?) ?? 0).toStringAsFixed(1)} / 5 seconds',
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (id == 'microphone' && state == 'intro')
            const SoftCard(
              child: Text(
                'PhoneCheck needs microphone access only to record and replay this test sample.',
              ),
            ),
          if (id == 'microphone' && state == 'permission')
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'Microphone Access Needed',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
          if (message.isNotEmpty)
            Semantics(
              liveRegion: true,
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          if (busy) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (measured.isNotEmpty) ...[
            const SizedBox(height: 16),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final e in measured.entries)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('${e.key}: ${_display(e.value)}'),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          if (!ready)
            PrimaryButton(
              label: state == 'intro' && id == 'microphone'
                  ? 'Allow Microphone & Begin Test'
                  : state == 'intro'
                  ? 'Begin Test'
                  : 'Retry Test',
              onPressed: busy ? null : begin,
            ),
          if (ready) ...[
            if (id == 'speaker' || id == 'earpiece')
              PrimaryButton(
                label: live['Playback started'] == true
                    ? 'Replay'
                    : 'Play Test Sound',
                icon: Icons.volume_up,
                onPressed: busy ? null : () => action('play'),
              ),
            if ((id == 'speaker' || id == 'earpiece') && playing) ...[
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Stop',
                secondary: true,
                icon: Icons.stop_rounded,
                onPressed: busy ? null : () => action('stopPlayback'),
              ),
            ],
            if (id == 'microphone') ...[
              PrimaryButton(
                label: live['recording'] == true
                    ? 'Stop Recording'
                    : recordingComplete
                    ? 'Record Again'
                    : 'Record 5 Seconds',
                icon: Icons.mic,
                onPressed: busy
                    ? null
                    : () => action(
                        live['recording'] == true ? 'stopRecording' : 'record',
                      ),
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Play Recording',
                secondary: true,
                onPressed: recordingComplete && !busy
                    ? () => action('play')
                    : null,
              ),
            ],
            if (id == 'haptics')
              PrimaryButton(
                label: 'Test Vibration',
                onPressed: busy ? null : () => action('haptic'),
              ),
            if (id == 'flash')
              PrimaryButton(
                label: live['torch'] == true
                    ? 'Turn Torch Off'
                    : 'Turn Torch On',
                onPressed: busy ? null : () => action('torch'),
              ),
            if (network)
              PrimaryButton(
                label: 'Refresh Check',
                secondary: true,
                onPressed: busy ? null : begin,
              ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Finish Test',
              onPressed: busy || (id == 'microphone' && !recordingComplete)
                  ? null
                  : finish,
            ),
          ],
          if (state == 'permission' || state == 'unavailable' || network)
            TextButton.icon(
              onPressed: () => action('settings'),
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: [
              TextButton(
                onPressed: () => mark(TestStatus.skipped),
                child: const Text('Skip Test'),
              ),
              TextButton(
                onPressed: () => mark(TestStatus.unavailable),
                child: const Text('Mark Unavailable'),
              ),
            ],
          ),
          if (simulator)
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Developer simulator override',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Text(
                    'Choose a simulated result to exercise the report flow. No hardware reading will be recorded.',
                  ),
                  TextButton(
                    onPressed: () => finish(simulated: true),
                    child: const Text('Set Simulated Result'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AudioWave extends StatefulWidget {
  const _AudioWave({required this.playing});
  final bool playing;

  @override
  State<_AudioWave> createState() => _AudioWaveState();
}

class _AudioWaveState extends State<_AudioWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );

  @override
  void initState() {
    super.initState();
    if (widget.playing) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _AudioWave oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing && !oldWidget.playing) {
      _controller.repeat(reverse: true);
    } else if (!widget.playing && oldWidget.playing) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 92,
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var index = 0; index < 7; index++)
            Container(
              width: 7,
              height:
                  (24 +
                          ((index.isEven ? 1 : .55) *
                              44 *
                              (widget.playing ? .45 + _controller.value : .15)))
                      .toDouble(),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
        ],
      ),
    ),
  );
}

String _display(Object? value) => value is bool
    ? (value ? 'Yes' : 'No')
    : value is double
    ? value.toStringAsFixed(2)
    : '$value';
String _instructions(String id, String fallback) => switch (id) {
  'speaker' => 'Play the bundled test tones at a comfortable volume. Listen at the bottom speaker for clarity and distortion. Disconnect headphones and check the actual route shown below.',
  'earpiece' => 'Hold the top receiver near your ear and play the sound at a comfortable volume. iOS selects the output route; verify the route shown and where you hear the sound. This does not place a call.',
  'microphone' => 'Allow microphone access to record your voice for up to 5 seconds. Speak normally, then play it back and judge clarity. The temporary recording is deleted when you leave.',
  'front_camera' || 'rear_camera' => 'Allow camera access to inspect a live preview. Check for a clear image, artifacts and uneven areas. No photos or video are saved.',
  'focus' => 'Allow camera access. Point the camera at a nearby object, then a distant one. Tap the object in the preview to focus and observe whether it becomes sharp.',
  'flash' => 'Allow camera access, then explicitly turn on the rear torch. Check that it lights steadily. The torch turns off when you leave.',
  'accelerometer' => 'Begin to read motion data, then tilt the phone slowly. Watch the X, Y and Z acceleration values and the tilt illustration respond.',
  'gyroscope' => 'Begin to read motion data, then rotate the phone slowly. Watch the pitch, roll and yaw attitude readings respond.',
  'compass' => 'Allow location access for the compass test. Rotate the phone away from magnets and check whether the magnetic heading changes.',
  'proximity' => 'Cover and uncover the top of the phone. The display may turn off while covered. Uncover it to see the detected/removed state.',
  'haptics' => 'Tap Test Vibration while holding the phone. Judge whether you feel the feedback.',
  'wifi' => 'Begin to read the current network path. Use Settings to connect to Wi-Fi and verify that browsing works. A network path alone does not test Wi-Fi hardware or internet reachability.',
  'bluetooth' => 'Begin to request Bluetooth access and read its power state. Use Settings to pair a known accessory and verify the connection. Powered On alone does not prove the radio works.',
  'gps' => 'Allow location access when you begin. Wait for a usable location update and its accuracy. Coordinates are neither displayed nor saved. This checks location services, not a specific GPS satellite receiver.',
  'cellular' => 'Check SIM/eSIM service and signal in Settings. Turn Wi-Fi off and verify mobile data, then restore Wi-Fi. iOS may not expose carrier or SIM details to this app.',
  _ => fallback,
};
