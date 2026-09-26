import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var deviceInfoChannel: DeviceInfoChannel?
  private var diagnostics: DiagnosticsChannel?
  private var reports: ReportChannel?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar = engineBridge.applicationRegistrar
    deviceInfoChannel = DeviceInfoChannel(messenger: registrar.messenger())
    let diagnostics = DiagnosticsChannel(messenger: registrar.messenger())
    self.diagnostics = diagnostics
    registrar.register(CameraPreviewFactory(service: diagnostics.camera), withId: "com.phonecheck/camera-preview")
    reports = ReportChannel(messenger: registrar.messenger())
  }
}
