import Flutter

final class DeviceInfoChannel {
  private let channel: FlutterMethodChannel
  private let service = DeviceInfoService()

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "com.phonecheck/device", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { result(FlutterMethodNotImplemented); return }
      switch call.method {
      case "getStaticInfo": result(self.service.staticInfo())
      case "getDynamicInfo": result(self.service.dynamicInfo())
      case "checkBluetooth": self.service.checkBluetooth(result: result)
      case "cancelLocation": self.service.cancelLocation(); result(nil)
      case "checkLocation": self.service.checkLocation(result: result)
      case "checkCameraPermission": self.service.checkCameraPermission(result: result)
      case "checkMicrophonePermission": self.service.checkMicrophonePermission(result: result)
      case "checkBiometrics": self.service.checkBiometrics(result: result)
      default: result(FlutterMethodNotImplemented)
      }
    }
  }
}
