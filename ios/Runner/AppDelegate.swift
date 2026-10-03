import AppTrackingTransparency
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var deviceInfoChannel: DeviceInfoChannel?
  private var diagnostics: DiagnosticsChannel?
  private var reports: ReportChannel?
  private var trackingChannel: FlutterMethodChannel?
  private var trackingResults: [FlutterResult] = []
  private var trackingActiveObserver: NSObjectProtocol?
  private var trackingRequestInFlight = false
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
    trackingChannel = FlutterMethodChannel(
      name: "com.phonecheck/tracking", binaryMessenger: registrar.messenger())
    trackingChannel?.setMethodCallHandler { [weak self] call, result in
      guard call.method == "requestAuthorization" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.trackingResults.append(result)
      self?.requestTrackingAuthorizationWhenActive()
    }
  }

  private func requestTrackingAuthorizationWhenActive() {
    guard UIApplication.shared.applicationState == .active else {
      if trackingActiveObserver == nil {
        trackingActiveObserver = NotificationCenter.default.addObserver(
          forName: UIApplication.didBecomeActiveNotification,
          object: nil,
          queue: .main
        ) { [weak self] _ in
          self?.requestTrackingAuthorizationWhenActive()
        }
      }
      return
    }

    if let observer = trackingActiveObserver {
      NotificationCenter.default.removeObserver(observer)
      trackingActiveObserver = nil
    }
    guard !trackingRequestInFlight else { return }

    let status = ATTrackingManager.trackingAuthorizationStatus
    guard status == .notDetermined else {
      completeTrackingRequests(with: status.rawValue)
      return
    }

    trackingRequestInFlight = true
    ATTrackingManager.requestTrackingAuthorization { [weak self] status in
      DispatchQueue.main.async {
        self?.trackingRequestInFlight = false
        self?.completeTrackingRequests(with: status.rawValue)
      }
    }
  }

  private func completeTrackingRequests(with status: UInt) {
    let results = trackingResults
    trackingResults.removeAll()
    for result in results {
      result(status)
    }
  }
}
