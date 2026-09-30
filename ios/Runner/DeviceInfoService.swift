import AVFoundation
import CoreBluetooth
import CoreHaptics
import CoreLocation
import CoreMotion
import CoreTelephony
import Flutter
import Foundation
import LocalAuthentication
import Network
import UIKit
import os

final class DeviceInfoService: NSObject, CBCentralManagerDelegate, CLLocationManagerDelegate {
  private let pathMonitor = NWPathMonitor()
  private let pathQueue = DispatchQueue(label: "com.phonecheck.network-path")
  private var path: NWPath?
  private var bluetoothManager: CBCentralManager?
  private var bluetoothResult: FlutterResult?
  private var locationManager: CLLocationManager?
  private var locationResult: FlutterResult?
  private var locationTimeout: Timer?
  private let telephony = CTTelephonyNetworkInfo()

  override init() {
    super.init()
    UIDevice.current.isBatteryMonitoringEnabled = true
    pathMonitor.pathUpdateHandler = { [weak self] current in
      DispatchQueue.main.async { self?.path = current }
    }
    pathMonitor.start(queue: pathQueue)
  }

  deinit { pathMonitor.cancel(); locationTimeout?.invalidate() }

  private func boxed(_ value: Any?) -> Any { value ?? NSNull() }

  private func machineIdentifier() -> String {
    var info = utsname()
    uname(&info)
    return withUnsafeBytes(of: &info.machine) { bytes in
      String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
    }
  }

  private func architecture() -> String {
    #if arch(arm64)
    return "arm64"
    #elseif arch(x86_64)
    return "x86_64"
    #else
    return "Unknown"
    #endif
  }

  func staticInfo() -> [String: Any] {
    let device = UIDevice.current
    let process = ProcessInfo.processInfo
    let hardware = machineIdentifier()
    #if targetEnvironment(simulator)
    let simulator = true
    let simulatedModel = process.environment["SIMULATOR_MODEL_IDENTIFIER"]
    #else
    let simulator = false
    let simulatedModel: String? = nil
    #endif
    let catalogIdentifier = simulatedModel ?? hardware
    let version = process.operatingSystemVersion
    let versionText = "\(version.majorVersion).\(version.minorVersion)" +
      (version.patchVersion > 0 ? ".\(version.patchVersion)" : "")
    let motion = CMMotionManager()
    let screen = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }.first?.screen ?? UIScreen.main
    let bounds = screen.bounds
    let native = screen.nativeBounds
    let capabilities = CHHapticEngine.capabilitiesForHardware()
    let bundle = Bundle.main
    let currentLocale = Locale.current
    let region: String?
    let measurementSystem: String
    if #available(iOS 16.0, *) {
      region = currentLocale.region?.identifier
      measurementSystem = currentLocale.measurementSystem.identifier
    } else {
      region = currentLocale.regionCode
      measurementSystem = currentLocale.usesMetricSystem ? "metric" : "us"
    }
    let authentication = biometricInfo()

    return [
      "identity": [
        "modelName": HardwareModelCatalog.displayName(for: catalogIdentifier, family: device.model),
        "hardwareIdentifier": hardware,
        "simulatedModelIdentifier": boxed(simulatedModel),
        "knownModel": HardwareModelCatalog.names[catalogIdentifier] != nil,
        "deviceClass": device.model,
        "localizedModel": device.localizedModel,
        "isSimulator": simulator,
        "architecture": architecture(),
        "systemName": device.systemName,
        "osVersion": versionText
      ],
      "memory": [
        "physicalBytes": NSNumber(value: process.physicalMemory),
        "processorCount": process.processorCount,
        "activeProcessorCount": process.activeProcessorCount
      ],
      "display": [
        "logicalWidth": bounds.width,
        "logicalHeight": bounds.height,
        "nativeWidth": Int(native.width),
        "nativeHeight": Int(native.height),
        "scale": screen.scale,
        "nativeScale": screen.nativeScale,
        "maximumFramesPerSecond": screen.maximumFramesPerSecond
      ],
      "sensors": [
        "accelerometer": motion.isAccelerometerAvailable,
        "gyroscope": motion.isGyroAvailable,
        "magnetometer": motion.isMagnetometerAvailable,
        "deviceMotion": motion.isDeviceMotionAvailable
      ],
      "haptics": [
        "supported": capabilities.supportsHaptics,
        "audioSupported": capabilities.supportsAudio
      ],
      "cameras": discoverCameras(),
      "biometrics": authentication,
      "preferences": [
        "locale": currentLocale.identifier,
        "region": boxed(region),
        "language": boxed(Locale.preferredLanguages.first),
        "measurementSystem": measurementSystem,
        "timeZone": TimeZone.current.identifier,
        "calendar": String(describing: Calendar.current.identifier)
      ],
      "app": [
        "version": boxed(bundle.infoDictionary?["CFBundleShortVersionString"] as? String),
        "build": boxed(bundle.infoDictionary?["CFBundleVersion"] as? String),
        "bundleIdentifier": boxed(bundle.bundleIdentifier)
      ]
    ]
  }

  func dynamicInfo() -> [String: Any] {
    let device = UIDevice.current
    let process = ProcessInfo.processInfo
    let batteryLevel = device.batteryLevel >= 0 ? Int((device.batteryLevel * 100).rounded()) : nil
    let batteryState: String
    switch device.batteryState {
    case .charging: batteryState = "Charging"
    case .full: batteryState = "Full"
    case .unplugged: batteryState = "Unplugged"
    default: batteryState = "Unknown"
    }
    let powerConnected: Bool? = batteryState == "Unknown" ? nil :
      (batteryState == "Charging" || batteryState == "Full")
    let thermal: String
    switch process.thermalState {
    case .nominal: thermal = "Nominal"
    case .fair: thermal = "Fair"
    case .serious: thermal = "Serious"
    case .critical: thermal = "Critical"
    @unknown default: thermal = "Unknown"
    }
    let screen = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }.first?.screen ?? UIScreen.main
    let availableToProcess = os_proc_available_memory()
    let network = networkInfo()
    return [
      "battery": [
        "levelPercent": boxed(batteryLevel),
        "state": batteryState,
        "powerConnected": boxed(powerConnected),
        "lowPowerMode": process.isLowPowerModeEnabled
      ],
      "storage": storageInfo(),
      "memoryDynamic": [
        "availableToProcessBytes": availableToProcess > 0 ? NSNumber(value: availableToProcess) : NSNull()
      ],
      "systemStatus": ["thermalState": thermal, "lowPowerMode": process.isLowPowerModeEnabled],
      "displayDynamic": ["brightnessPercent": Int((screen.brightness * 100).rounded())],
      "network": network,
      "cellular": cellularInfo()
    ]
  }

  private func storageInfo() -> [String: Any] {
    do {
      let url = URL(fileURLWithPath: NSHomeDirectory())
      let values = try url.resourceValues(forKeys: [
        .volumeTotalCapacityKey,
        .volumeAvailableCapacityKey,
        .volumeAvailableCapacityForImportantUsageKey,
        .volumeAvailableCapacityForOpportunisticUsageKey
      ])
      let total = values.volumeTotalCapacity
      let available = values.volumeAvailableCapacity
      return [
        "totalBytes": boxed(total),
        "availableBytes": boxed(available),
        "usedBytes": boxed(total != nil && available != nil ? max(0, total! - available!) : nil),
        "importantBytes": boxed(values.volumeAvailableCapacityForImportantUsage),
        "opportunisticBytes": boxed(values.volumeAvailableCapacityForOpportunisticUsage)
      ]
    } catch {
      return ["totalBytes": NSNull(), "availableBytes": NSNull(), "usedBytes": NSNull(),
              "importantBytes": NSNull(), "opportunisticBytes": NSNull()]
    }
  }

  private func networkInfo() -> [String: Any] {
    guard let path = path else {
      return ["status": "Unknown", "interface": NSNull(), "expensive": NSNull(), "constrained": NSNull()]
    }
    let interface: String?
    if path.usesInterfaceType(.wifi) { interface = "Wi-Fi" }
    else if path.usesInterfaceType(.cellular) { interface = "Cellular" }
    else if path.usesInterfaceType(.wiredEthernet) { interface = "Wired Ethernet" }
    else if path.status == .satisfied { interface = "Other" }
    else { interface = nil }
    return [
      "status": path.status == .satisfied ? "Available" : "Unavailable",
      "interface": boxed(interface),
      "expensive": path.isExpensive,
      "constrained": path.isConstrained
    ]
  }

  private func cellularInfo() -> [String: Any] {
    let technologies = telephony.serviceCurrentRadioAccessTechnology ?? [:]
    let dataService = telephony.dataServiceIdentifier
    let raw: String?
    if let dataService = dataService {
      raw = technologies[dataService] ?? technologies.values.first
    } else {
      raw = technologies.values.first
    }
    let display: String?
    switch raw {
    case CTRadioAccessTechnologyNR: display = "5G NR"
    case CTRadioAccessTechnologyNRNSA: display = "5G NSA"
    case CTRadioAccessTechnologyLTE: display = "LTE"
    case CTRadioAccessTechnologyWCDMA, CTRadioAccessTechnologyHSDPA,
         CTRadioAccessTechnologyHSUPA, CTRadioAccessTechnologyCDMAEVDORev0,
         CTRadioAccessTechnologyCDMAEVDORevA, CTRadioAccessTechnologyCDMAEVDORevB:
      display = "3G"
    case CTRadioAccessTechnologyEdge, CTRadioAccessTechnologyGPRS:
      display = "2G"
    default: display = raw
    }
    return ["radioTechnology": boxed(display)]
  }

  private func discoverCameras() -> [[String: Any]] {
    var types: [AVCaptureDevice.DeviceType] = [
      .builtInWideAngleCamera, .builtInUltraWideCamera, .builtInTelephotoCamera,
      .builtInTrueDepthCamera, .builtInDualCamera, .builtInDualWideCamera,
      .builtInTripleCamera
    ]
    if #available(iOS 15.4, *) { types.append(.builtInLiDARDepthCamera) }
    let session = AVCaptureDevice.DiscoverySession(
      deviceTypes: types, mediaType: .video, position: .unspecified)
    return session.devices.map { camera in
      let position = camera.position == .front ? "Front" :
        camera.position == .back ? "Rear" : "Unspecified"
      let type: String
      if #available(iOS 15.4, *), camera.deviceType == .builtInLiDARDepthCamera {
        type = "LiDAR Depth"
      } else { switch camera.deviceType {
      case .builtInWideAngleCamera: type = "Wide"
      case .builtInUltraWideCamera: type = "Ultra Wide"
      case .builtInTelephotoCamera: type = "Telephoto"
      case .builtInTrueDepthCamera: type = "TrueDepth"
      case .builtInDualCamera: type = "Dual"
      case .builtInDualWideCamera: type = "Dual Wide"
      case .builtInTripleCamera: type = "Triple"
      default: type = "Other"
      } }
      return [
        "position": position, "name": camera.localizedName, "type": type,
        "connected": camera.isConnected, "virtual": camera.isVirtualDevice,
        "constituents": camera.constituentDevices.map { $0.localizedName },
        "hasTorch": camera.hasTorch, "torchAvailable": camera.isTorchAvailable,
        "hasFlash": camera.hasFlash
      ]
    }
  }

  private func biometricInfo() -> [String: Any] {
    let context = LAContext()
    var error: NSError?
    let canUse = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    let type: String
    switch context.biometryType {
    case .faceID: type = "Face ID"
    case .touchID: type = "Touch ID"
    case .opticID: type = "Optic ID"
    default: type = "None"
    }
    let status: String
    if canUse { status = "Available" }
    else if error?.code == LAError.biometryNotEnrolled.rawValue { status = "Not Enrolled" }
    else if error?.code == LAError.biometryLockout.rawValue { status = "Temporarily Locked" }
    else if error?.code == LAError.biometryNotAvailable.rawValue { status = "Unavailable" }
    else { status = "Unavailable" }
    return ["type": type, "status": status]
  }

  func checkCameraPermission(result: @escaping FlutterResult) {
    AVCaptureDevice.requestAccess(for: .video) { allowed in
      DispatchQueue.main.async { result(["status": allowed ? "Authorized" : "Denied"]) }
    }
  }

  func checkMicrophonePermission(result: @escaping FlutterResult) {
    AVAudioSession.sharedInstance().requestRecordPermission { allowed in
      DispatchQueue.main.async { result(["status": allowed ? "Authorized" : "Denied"]) }
    }
  }

  func checkBiometrics(result: @escaping FlutterResult) {
    let context = LAContext()
    var error: NSError?
    guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
      result(["status": biometricInfo()["status"] ?? "Unavailable"])
      return
    }
    context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
      localizedReason: "Check biometric authentication when you choose to test it") { success, error in
      DispatchQueue.main.async {
        result(["status": success ? "Authenticated" :
          ((error as NSError?)?.code == LAError.userCancel.rawValue ? "Cancelled" : "Failed")])
      }
    }
  }

  func checkBluetooth(result: @escaping FlutterResult) {
    guard bluetoothResult == nil else { result(["status": "Checking"]); return }
    bluetoothResult = result
    bluetoothManager = CBCentralManager(delegate: self, queue: nil,
      options: [CBCentralManagerOptionShowPowerAlertKey: false])
  }

  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    let status: String
    switch central.state {
    case .poweredOn: status = "Powered On"
    case .poweredOff: status = "Powered Off"
    case .unsupported: status = "Unsupported"
    case .unauthorized: status = "Unauthorized"
    case .resetting: status = "Resetting"
    case .unknown: status = "Unknown"
    @unknown default: status = "Unknown"
    }
    if let result = bluetoothResult {
      bluetoothResult = nil
      result(["status": status])
    }
  }

  func checkLocation(result: @escaping FlutterResult) {
    guard locationResult == nil else { result(["status": "Checking"]); return }
    guard CLLocationManager.locationServicesEnabled() else {
      result(["status": "Location Services Off"]); return
    }
    locationResult = result
    let manager = CLLocationManager()
    locationManager = manager
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    locationTimeout = Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { [weak self] _ in
      self?.finishLocation(["status": "Timed Out"])
    }
    let authorization = manager.authorizationStatus
    if authorization == .notDetermined { manager.requestWhenInUseAuthorization() }
    else { continueLocationCheck(authorization) }
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    guard locationResult != nil else { return }
    continueLocationCheck(manager.authorizationStatus)
  }

  private func continueLocationCheck(_ authorization: CLAuthorizationStatus) {
    switch authorization {
    case .authorizedAlways, .authorizedWhenInUse: locationManager?.requestLocation()
    case .denied: finishLocation(["status": "Denied"])
    case .restricted: finishLocation(["status": "Restricted"])
    case .notDetermined: break
    @unknown default: finishLocation(["status": "Unavailable"])
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last, location.horizontalAccuracy >= 0, abs(location.timestamp.timeIntervalSinceNow) < 30 else { finishLocation(["status": "Unavailable"]); return }
    finishLocation(["status": "Available", "accuracyMeters": location.horizontalAccuracy])
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    finishLocation(["status": "Unavailable"])
  }

  func cancelLocation() { finishLocation(["status": "Interrupted"]) }

  private func finishLocation(_ data: [String: Any]) {
    locationTimeout?.invalidate()
    locationTimeout = nil
    locationManager?.stopUpdatingLocation()
    locationManager?.delegate = nil
    locationManager = nil
    let result = locationResult
    locationResult = nil
    result?(data)
  }
}
