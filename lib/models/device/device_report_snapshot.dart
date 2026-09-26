import 'phone_device_info.dart';

class DeviceReportSnapshot {
  const DeviceReportSnapshot({
    required this.model,
    this.hardwareIdentifier,
    this.osVersion,
    this.storageTotalBytes,
    this.storageAvailableBytes,
    this.batteryPercent,
    this.nativeWidth,
    this.nativeHeight,
    this.maximumRefreshRate,
    this.cameraConfiguration,
  });

  final String model;
  final String? hardwareIdentifier;
  final String? osVersion;
  final int? storageTotalBytes;
  final int? storageAvailableBytes;
  final int? batteryPercent;
  final int? nativeWidth;
  final int? nativeHeight;
  final int? maximumRefreshRate;
  final String? cameraConfiguration;

  Map<String, Object?> toJson() => {
    'model': model,
    'hardwareIdentifier': hardwareIdentifier,
    'osVersion': osVersion,
    'storageTotalBytes': storageTotalBytes,
    'storageAvailableBytes': storageAvailableBytes,
    'batteryPercent': batteryPercent,
    'nativeWidth': nativeWidth,
    'nativeHeight': nativeHeight,
    'maximumRefreshRate': maximumRefreshRate,
    'cameraConfiguration': cameraConfiguration,
  };
  factory DeviceReportSnapshot.fromJson(Map<String, dynamic> json) =>
      DeviceReportSnapshot(
        model: json['model'] as String? ?? 'iPhone',
        hardwareIdentifier: json['hardwareIdentifier'] as String?,
        osVersion: json['osVersion'] as String?,
        storageTotalBytes: json['storageTotalBytes'] as int?,
        storageAvailableBytes: json['storageAvailableBytes'] as int?,
        batteryPercent: json['batteryPercent'] as int?,
        nativeWidth: json['nativeWidth'] as int?,
        nativeHeight: json['nativeHeight'] as int?,
        maximumRefreshRate: json['maximumRefreshRate'] as int?,
        cameraConfiguration: json['cameraConfiguration'] as String?,
      );

  factory DeviceReportSnapshot.fromInfo(PhoneDeviceInfo info) {
    final rear = info.cameras.where(
      (camera) => camera.position == 'Rear' && camera.connected,
    );
    final configuration =
        rear
            .where((camera) => camera.virtual)
            .map((camera) => camera.type)
            .firstOrNull ??
        (rear.isNotEmpty ? rear.map((camera) => camera.type).join(', ') : null);
    return DeviceReportSnapshot(
      model:
          info.identity.text('modelName') ??
          info.identity.text('deviceClass') ??
          'iPhone',
      hardwareIdentifier: info.identity.text('hardwareIdentifier'),
      osVersion: info.identity.text('osVersion'),
      storageTotalBytes: info.storage.integer('totalBytes'),
      storageAvailableBytes: info.storage.integer('availableBytes'),
      batteryPercent: info.battery.integer('levelPercent'),
      nativeWidth: info.display.integer('nativeWidth'),
      nativeHeight: info.display.integer('nativeHeight'),
      maximumRefreshRate: info.display.integer('maximumFramesPerSecond'),
      cameraConfiguration: configuration,
    );
  }
}
