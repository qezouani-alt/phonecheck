import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../main.dart';
import '../../models/device/device_format.dart';
import '../../models/device/model_specifications.dart';
import '../../models/device/phone_device_info.dart';
import '../../services/device/device_info_controller.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/device_info/device_info_section.dart';
import '../../widgets/device_info/storage_usage_bar.dart';
import '../../widgets/info_row.dart';
import '../../widgets/primary_button.dart';

class DeviceInfoScreen extends StatelessWidget {
  const DeviceInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = DeviceInfoScope.of(context);
    final info = controller.info;
    return AppShell(
      title: 'Device Information',
      child: info == null
          ? _empty(context, controller)
          : RefreshIndicator(
              onRefresh: controller.refresh,
              child: PageContent(children: _content(context, controller, info)),
            ),
    );
  }

  Widget _empty(BuildContext context, DeviceInfoController controller) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                controller.loading
                    ? Icons.phone_iphone_rounded
                    : Icons.info_outline_rounded,
                size: 58,
                color: AppColors.blue,
              ),
              const SizedBox(height: 16),
              Text(
                controller.loading
                    ? 'Reading device information…'
                    : 'Device Information Unavailable',
                textAlign: TextAlign.center,
                style: AppTextStyles.section,
              ),
              const SizedBox(height: 7),
              Text(
                controller.error ?? 'PhoneCheck is checking what this device shares through public iOS APIs.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
              if (!controller.loading) ...[
                const SizedBox(height: 20),
                PrimaryButton(label: 'Try Again', onPressed: controller.load),
              ],
            ],
          ),
        ),
      );

  List<Widget> _content(
    BuildContext context,
    DeviceInfoController controller,
    PhoneDeviceInfo info,
  ) {
    final identity = info.identity;
    final storage = info.storage;
    final display = info.display;
    final identifier =
        identity.text('simulatedModelIdentifier') ??
        identity.text('hardwareIdentifier');
    final specs = identifier == null
        ? null
        : ModelSpecifications.byIdentifier[identifier];
    String value(String? input) => DeviceFormat.text(input);
    String number(int? input, String suffix) =>
        input == null ? 'Unavailable' : '$input $suffix';
    String capability(bool? input) => DeviceFormat.available(input);
    return [
      const Text('Device Information', style: AppTextStyles.largeTitle),
      const SizedBox(height: 15),
      SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(
                    Icons.phone_iphone_rounded,
                    color: AppColors.blue,
                    size: 31,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value(identity.text('modelName')),
                        style: AppTextStyles.section,
                      ),
                      Text(
                        '${value(identity.text('systemName'))} ${value(identity.text('osVersion'))}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value(identifier),
              style: AppTextStyles.secondary.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (identity.boolean('isSimulator') == true) ...[
              const SizedBox(height: 7),
              const Text(
                'Simulator · values describe the simulated environment',
                style: TextStyle(fontSize: 12, color: AppColors.amber),
              ),
            ],
            if (identity.boolean('knownModel') == false &&
                identifier?.startsWith('iPhone') == true)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Unknown model identifier: $identifier',
                  style: const TextStyle(fontSize: 12, color: AppColors.amber),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 13),
      Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          DeviceInfoChip(
            icon: Icons.battery_5_bar_rounded,
            label:
                '${DeviceFormat.percent(info.battery.integer('levelPercent'))} Battery',
          ),
          DeviceInfoChip(
            icon: Icons.storage_rounded,
            label:
                '${DeviceFormat.bytes(storage.integer('availableBytes'))} Free',
          ),
          DeviceInfoChip(
            icon: Icons.speed_rounded,
            label: number(display.integer('maximumFramesPerSecond'), 'Hz'),
          ),
          DeviceInfoChip(
            icon: Icons.memory_rounded,
            label: number(info.memory.integer('processorCount'), 'CPU Cores'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (controller.error != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            controller.error!,
            style: const TextStyle(color: AppColors.amber, fontSize: 13),
          ),
        ),
      DeviceInfoSection(
        title: 'Device',
        icon: Icons.phone_iphone_rounded,
        expanded: true,
        children: [
          InfoRow(label: 'Model', value: value(identity.text('modelName'))),
          InfoRow(
            label: 'Hardware Identifier',
            value: value(identity.text('hardwareIdentifier')),
          ),
          if (identity.text('simulatedModelIdentifier') != null)
            InfoRow(
              label: 'Simulated Model',
              value: value(identity.text('simulatedModelIdentifier')),
            ),
          InfoRow(
            label: 'Device Class',
            value: value(identity.text('deviceClass')),
          ),
          InfoRow(
            label: 'Localized Model',
            value: value(identity.text('localizedModel')),
          ),
          InfoRow(
            label: 'Device Type',
            value: identity.boolean('isSimulator') == true
                ? 'Simulator'
                : 'Physical Device',
          ),
          InfoRow(
            label: 'Architecture',
            value: value(identity.text('architecture')),
          ),
          InfoRow(
            label: 'System',
            value:
                '${value(identity.text('systemName'))} ${value(identity.text('osVersion'))}',
          ),
        ],
      ),
      DeviceInfoSection(
        title: 'Battery',
        icon: Icons.battery_5_bar_rounded,
        expanded: true,
        note: 'Exact battery health and cycle count are not available to third-party apps through standard public iOS APIs.',
        children: [
          InfoRow(
            label: 'Charge',
            value: DeviceFormat.percent(info.battery.integer('levelPercent')),
          ),
          InfoRow(label: 'Status', value: value(info.battery.text('state'))),
          InfoRow(
            label: 'Connected to Power',
            value: DeviceFormat.yesNo(info.battery.boolean('powerConnected')),
          ),
          InfoRow(
            label: 'Low Power Mode',
            value: DeviceFormat.onOff(info.battery.boolean('lowPowerMode')),
          ),
        ],
      ),
      DeviceInfoSection(
        title: 'Storage',
        icon: Icons.storage_rounded,
        expanded: true,
        children: [
          StorageUsageBar(
            totalBytes: storage.integer('totalBytes'),
            availableBytes: storage.integer('availableBytes'),
          ),
          InfoRow(
            label: 'Capacity',
            value: DeviceFormat.bytes(storage.integer('totalBytes')),
          ),
          InfoRow(
            label: 'Used',
            value: DeviceFormat.bytes(storage.integer('usedBytes')),
          ),
          InfoRow(
            label: 'Available',
            value: DeviceFormat.bytes(storage.integer('availableBytes')),
          ),
          InfoRow(
            label: 'For Important Usage',
            value: DeviceFormat.bytes(storage.integer('importantBytes')),
          ),
          InfoRow(
            label: 'For Opportunistic Usage',
            value: DeviceFormat.bytes(storage.integer('opportunisticBytes')),
          ),
        ],
      ),
      DeviceInfoSection(
        title: 'Memory & Processor',
        icon: Icons.memory_rounded,
        note: 'Memory available to PhoneCheck is a process limit estimate, not free system RAM.',
        children: [
          InfoRow(
            label: 'Physical Memory',
            value: DeviceFormat.bytes(info.memory.integer('physicalBytes')),
          ),
          InfoRow(
            label: 'Available to PhoneCheck',
            value: DeviceFormat.bytes(
              info.memoryDynamic.integer('availableToProcessBytes'),
            ),
          ),
          InfoRow(
            label: 'CPU Cores',
            value: number(info.memory.integer('processorCount'), ''),
          ),
          InfoRow(
            label: 'Active Cores',
            value: number(info.memory.integer('activeProcessorCount'), ''),
          ),
        ],
      ),
      DeviceInfoSection(
        title: 'Display',
        icon: Icons.aspect_ratio_rounded,
        note: 'Maximum refresh rate is a display capability, not the current measured frame rate.',
        children: [
          InfoRow(
            label: 'Logical Size',
            value: _size(
              display.integer('logicalWidth'),
              display.integer('logicalHeight'),
              'pt',
            ),
          ),
          InfoRow(
            label: 'Native Resolution',
            value: _size(
              display.integer('nativeWidth'),
              display.integer('nativeHeight'),
              'px',
            ),
          ),
          InfoRow(label: 'Scale', value: _scale(display.number('scale'))),
          InfoRow(
            label: 'Native Scale',
            value: _scale(display.number('nativeScale')),
          ),
          InfoRow(
            label: 'Maximum Refresh Rate',
            value: number(display.integer('maximumFramesPerSecond'), 'Hz'),
          ),
          InfoRow(
            label: 'Current Brightness',
            value: DeviceFormat.percent(
              info.displayDynamic.integer('brightnessPercent'),
            ),
          ),
        ],
      ),
      DeviceInfoSection(
        title: 'System Status',
        icon: Icons.thermostat_rounded,
        note: 'Thermal state describes the current system state. It is not a hardware health result.',
        children: [
          InfoRow(
            label: 'Thermal State',
            value: value(info.systemStatus.text('thermalState')),
          ),
          InfoRow(
            label: 'Low Power Mode',
            value: DeviceFormat.onOff(
              info.systemStatus.boolean('lowPowerMode'),
            ),
          ),
        ],
      ),
      DeviceInfoSection(
        title: 'Cameras',
        icon: Icons.camera_alt_outlined,
        note: 'Detected camera hardware is a capability, not a passed camera test. Capture access is checked only when requested.',
        children: [
          InfoRow(label: 'Detected Devices', value: '${info.cameras.length}'),
          if (info.cameras.isEmpty)
            const InfoRow(label: 'Camera Hardware', value: 'Unavailable'),
          for (final camera in info.cameras) ...[
            InfoRow(
              label: '${camera.position} ${camera.type}',
              value: camera.connected ? 'Available' : 'Disconnected',
            ),
            InfoRow(label: 'Name', value: camera.name),
            InfoRow(
              label: 'Virtual Device',
              value: camera.virtual ? 'Yes' : 'No',
            ),
            if (camera.constituents.isNotEmpty)
              InfoRow(
                label: 'Constituents',
                value: camera.constituents.join(', '),
              ),
            InfoRow(
              label: 'Torch',
              value: camera.hasTorch
                  ? (camera.torchAvailable ? 'Available' : 'Unavailable')
                  : 'Not Present',
            ),
            InfoRow(
              label: 'Flash',
              value: camera.hasFlash ? 'Available' : 'Not Present',
            ),
            Divider(color: Theme.of(context).dividerColor),
          ],
          _check(
            controller,
            'camera',
            'Camera Capture Access',
            'Check Camera Access',
            'checkCameraPermission',
          ),
        ],
      ),
      DeviceInfoSection(
        title: 'Sensors',
        icon: Icons.sensors_rounded,
        note: 'Availability is a capability only. Interactive sensor tests are separate.',
        children: [
          InfoRow(
            label: 'Accelerometer',
            value: capability(info.sensors.boolean('accelerometer')),
          ),
          InfoRow(
            label: 'Gyroscope',
            value: capability(info.sensors.boolean('gyroscope')),
          ),
          InfoRow(
            label: 'Magnetometer',
            value: capability(info.sensors.boolean('magnetometer')),
          ),
          InfoRow(
            label: 'Device Motion',
            value: capability(info.sensors.boolean('deviceMotion')),
          ),
        ],
      ),
      DeviceInfoSection(
        title: 'Haptics',
        icon: Icons.vibration_rounded,
        note: 'Supported does not mean the haptic engine has passed a test.',
        children: [
          InfoRow(
            label: 'Haptic Engine',
            value: DeviceFormat.supported(info.haptics.boolean('supported')),
          ),
          InfoRow(
            label: 'Haptic Audio',
            value: DeviceFormat.supported(
              info.haptics.boolean('audioSupported'),
            ),
          ),
        ],
      ),
      DeviceInfoSection(
        title: 'Microphone',
        icon: Icons.mic_none_rounded,
        note: 'Microphone access is checked only when you request it. Permission does not prove recording quality.',
        children: [
          _check(
            controller,
            'microphone',
            'Recording Access',
            'Check Microphone Access',
            'checkMicrophonePermission',
          ),
        ],
      ),
      DeviceInfoSection(
        title: 'Biometrics',
        icon: Icons.face_rounded,
        note: 'The capability check does not authenticate or establish hardware health. Authentication starts only after you tap the button.',
        children: [
          InfoRow(label: 'Type', value: value(info.biometrics.text('type'))),
          InfoRow(
            label: 'Current Capability',
            value: value(info.biometrics.text('status')),
          ),
          _check(
            controller,
            'biometrics',
            'Authentication Check',
            'Test Authentication',
            'checkBiometrics',
          ),
        ],
      ),
      DeviceInfoSection(
        title: 'Connectivity',
        icon: Icons.wifi_rounded,
        note: 'A network path does not prove Internet quality or Wi-Fi hardware health. Location coordinates are not retained.',
        children: [
          InfoRow(
            label: 'Network Path',
            value: value(info.network.text('status')),
          ),
          InfoRow(
            label: 'Interface',
            value: value(info.network.text('interface')),
          ),
          InfoRow(
            label: 'Expensive Connection',
            value: DeviceFormat.yesNo(info.network.boolean('expensive')),
          ),
          InfoRow(
            label: 'Low Data Mode',
            value: DeviceFormat.onOff(info.network.boolean('constrained')),
          ),
          _check(
            controller,
            'bluetooth',
            'Bluetooth',
            'Check Bluetooth',
            'checkBluetooth',
          ),
          _check(
            controller,
            'location',
            'GPS / Location',
            'Check Location',
            'checkLocation',
          ),
          if (controller.locationAccuracyMeters != null)
            InfoRow(
              label: 'Location Accuracy',
              value:
                  '${controller.locationAccuracyMeters!.toStringAsFixed(0)} m',
            ),
        ],
      ),
      DeviceInfoSection(
        title: 'Cellular',
        icon: Icons.signal_cellular_alt_rounded,
        note: 'Cellular data may be unavailable on a simulator, iPad, or device without active service.',
        children: [
          InfoRow(
            label: 'Radio Technology',
            value: value(info.cellular.text('radioTechnology')),
          ),
        ],
      ),
      DeviceInfoSection(
        title: 'System Preferences',
        icon: Icons.settings_outlined,
        children: [
          InfoRow(
            label: 'Locale',
            value: value(info.preferences.text('locale')),
          ),
          InfoRow(
            label: 'Region',
            value: value(info.preferences.text('region')),
          ),
          InfoRow(
            label: 'Preferred Language',
            value: value(info.preferences.text('language')),
          ),
          InfoRow(
            label: 'Measurement System',
            value: value(info.preferences.text('measurementSystem')),
          ),
          InfoRow(
            label: 'Time Zone',
            value: value(info.preferences.text('timeZone')),
          ),
          InfoRow(
            label: 'Calendar',
            value: value(info.preferences.text('calendar')),
          ),
        ],
      ),
      DeviceInfoSection(
        title: 'App Information',
        icon: Icons.info_outline_rounded,
        children: [
          InfoRow(
            label: 'PhoneCheck Version',
            value: value(info.app.text('version')),
          ),
          InfoRow(label: 'Build', value: value(info.app.text('build'))),
          InfoRow(
            label: 'Bundle Identifier',
            value: value(info.app.text('bundleIdentifier')),
          ),
        ],
      ),
      DeviceInfoSection(
        title: 'Model Specifications',
        icon: Icons.menu_book_outlined,
        note: 'Reference specifications come from a local model database. They are not live hardware measurements.',
        children: specs == null
            ? [
                const InfoRow(
                  label: 'Reference',
                  value: 'Unavailable for this model',
                ),
              ]
            : [
                InfoRow(label: 'Release Year', value: '${specs.releaseYear}'),
                InfoRow(label: 'Chip Family', value: specs.chip),
                if (specs.expectedRam != null)
                  InfoRow(label: 'Expected RAM', value: specs.expectedRam!),
                InfoRow(label: 'Display Size', value: specs.displaySize),
                InfoRow(
                  label: 'Display Technology',
                  value: specs.displayTechnology,
                ),
                InfoRow(
                  label: 'ProMotion',
                  value: specs.proMotion ? 'Supported' : 'Not Supported',
                ),
                InfoRow(
                  label: 'Maximum Expected Refresh',
                  value: '${specs.maximumRefreshRate} Hz',
                ),
                InfoRow(
                  label: 'Biometric Family',
                  value: specs.biometricFamily,
                ),
                InfoRow(label: 'Camera Family', value: specs.cameraFamily),
                InfoRow(label: 'Connector', value: specs.connector),
              ],
      ),
      const SizedBox(height: 6),
      Text(
        'Pull down to refresh battery, storage, memory, brightness, network, and system state.',
        textAlign: TextAlign.center,
        style: AppTextStyles.secondary.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 18),
    ];
  }

  Widget _check(
    DeviceInfoController controller,
    String key,
    String label,
    String buttonLabel,
    String method,
  ) => DeviceInfoCheckRow(
    label: label,
    status: controller.checks[key] ?? 'Not Checked',
    buttonLabel: buttonLabel,
    checking: controller.checking.contains(key),
    onCheck: () => controller.runCheck(key, method),
  );

  String _size(int? width, int? height, String unit) =>
      width == null || height == null
      ? 'Unavailable'
      : '$width × $height $unit';
  String _scale(double? scale) => scale == null
      ? 'Unavailable'
      : '${scale.toStringAsFixed(scale == scale.roundToDouble() ? 0 : 2)}×';
}
