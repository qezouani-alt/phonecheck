class DeviceFacts {
  const DeviceFacts(this.values);
  final Map<String, Object?> values;

  factory DeviceFacts.from(Object? raw) {
    if (raw is! Map) return const DeviceFacts({});
    return DeviceFacts({
      for (final entry in raw.entries) entry.key.toString(): entry.value,
    });
  }

  String? text(String key) =>
      values[key] is String ? values[key] as String : null;
  int? integer(String key) =>
      values[key] is num ? (values[key] as num).toInt() : null;
  double? number(String key) =>
      values[key] is num ? (values[key] as num).toDouble() : null;
  bool? boolean(String key) => values[key] is bool ? values[key] as bool : null;
}

class CameraCapability {
  const CameraCapability({
    required this.position,
    required this.name,
    required this.type,
    required this.connected,
    required this.virtual,
    required this.constituents,
    required this.hasTorch,
    required this.torchAvailable,
    required this.hasFlash,
  });
  final String position;
  final String name;
  final String type;
  final bool connected;
  final bool virtual;
  final List<String> constituents;
  final bool hasTorch;
  final bool torchAvailable;
  final bool hasFlash;

  factory CameraCapability.from(Object? raw) {
    final facts = DeviceFacts.from(raw);
    final list = facts.values['constituents'];
    return CameraCapability(
      position: facts.text('position') ?? 'Unspecified',
      name: facts.text('name') ?? 'Camera',
      type: facts.text('type') ?? 'Other',
      connected: facts.boolean('connected') ?? false,
      virtual: facts.boolean('virtual') ?? false,
      constituents: list is List ? list.whereType<String>().toList() : const [],
      hasTorch: facts.boolean('hasTorch') ?? false,
      torchAvailable: facts.boolean('torchAvailable') ?? false,
      hasFlash: facts.boolean('hasFlash') ?? false,
    );
  }
}

class PhoneDeviceInfo {
  const PhoneDeviceInfo({
    required this.identity,
    required this.memory,
    required this.display,
    required this.sensors,
    required this.haptics,
    required this.biometrics,
    required this.preferences,
    required this.app,
    required this.cameras,
    required this.battery,
    required this.storage,
    required this.memoryDynamic,
    required this.systemStatus,
    required this.displayDynamic,
    required this.network,
    required this.cellular,
  });

  final DeviceFacts identity;
  final DeviceFacts memory;
  final DeviceFacts display;
  final DeviceFacts sensors;
  final DeviceFacts haptics;
  final DeviceFacts biometrics;
  final DeviceFacts preferences;
  final DeviceFacts app;
  final List<CameraCapability> cameras;
  final DeviceFacts battery;
  final DeviceFacts storage;
  final DeviceFacts memoryDynamic;
  final DeviceFacts systemStatus;
  final DeviceFacts displayDynamic;
  final DeviceFacts network;
  final DeviceFacts cellular;

  factory PhoneDeviceInfo.fromMaps(
    Map<String, Object?> staticData,
    Map<String, Object?> dynamicData,
  ) {
    DeviceFacts staticFacts(String key) => DeviceFacts.from(staticData[key]);
    DeviceFacts dynamicFacts(String key) => DeviceFacts.from(dynamicData[key]);
    final cameraList = staticData['cameras'];
    return PhoneDeviceInfo(
      identity: staticFacts('identity'),
      memory: staticFacts('memory'),
      display: staticFacts('display'),
      sensors: staticFacts('sensors'),
      haptics: staticFacts('haptics'),
      biometrics: staticFacts('biometrics'),
      preferences: staticFacts('preferences'),
      app: staticFacts('app'),
      cameras: cameraList is List
          ? cameraList.map(CameraCapability.from).toList()
          : const [],
      battery: dynamicFacts('battery'),
      storage: dynamicFacts('storage'),
      memoryDynamic: dynamicFacts('memoryDynamic'),
      systemStatus: dynamicFacts('systemStatus'),
      displayDynamic: dynamicFacts('displayDynamic'),
      network: dynamicFacts('network'),
      cellular: dynamicFacts('cellular'),
    );
  }

  PhoneDeviceInfo withDynamic(Map<String, Object?> dynamicData) =>
      PhoneDeviceInfo.fromMaps({
        'identity': identity.values,
        'memory': memory.values,
        'display': display.values,
        'sensors': sensors.values,
        'haptics': haptics.values,
        'biometrics': biometrics.values,
        'preferences': preferences.values,
        'app': app.values,
        'cameras': cameras
            .map(
              (camera) => {
                'position': camera.position,
                'name': camera.name,
                'type': camera.type,
                'connected': camera.connected,
                'virtual': camera.virtual,
                'constituents': camera.constituents,
                'hasTorch': camera.hasTorch,
                'torchAvailable': camera.torchAvailable,
                'hasFlash': camera.hasFlash,
              },
            )
            .toList(),
      }, dynamicData);
}
