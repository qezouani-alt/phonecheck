import Flutter
import AVFoundation
import UIKit

final class DiagnosticsChannel {
  let camera = CameraDiagnosticService()
  private let audio = AudioDiagnosticService()
  private let sensors = SensorDiagnosticService()
  private let channel: FlutterMethodChannel
  private var active = ""
  private var generation = 0
  private var interrupted = false
  private var observers: [NSObjectProtocol] = []
  private var simulator: Bool {
    #if targetEnvironment(simulator)
    return true
    #else
    return false
    #endif
  }
  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "com.phonecheck/diagnostics", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result) }
    for name in [UIApplication.didEnterBackgroundNotification, AVAudioSession.interruptionNotification, AVAudioSession.routeChangeNotification, .AVCaptureSessionWasInterrupted, .AVCaptureSessionRuntimeError] {
      observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] notification in
        guard let self = self, !self.active.isEmpty else { return }
        if name == AVAudioSession.routeChangeNotification {
          let reason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
          guard reason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue || reason == AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue else { return }
        }
        self.stop(); self.interrupted = true
      })
    }
  }
  deinit { observers.forEach { NotificationCenter.default.removeObserver($0) } }
  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "environment": result(["simulator": simulator])
    case "settings":
      if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
      result(nil)
    case "stop": stop(); result(nil)
    case "sample":
      if interrupted { result(["error": "Test interrupted. Begin again to resume."]); return }
      if ["speaker","earpiece","microphone"].contains(active) { result(audio.sample()) }
      else if ["front_camera","rear_camera","focus","flash"].contains(active) { result(camera.sample()) }
      else { result(sensors.sample()) }
    case "start":
      stop(); interrupted = false
      let id = args["id"] as? String ?? ""
      if simulator { result(["status": "unavailable", "message": "Unavailable in Simulator", "simulator": true]); return }
      active = id
      let token = generation
      if ["front_camera","rear_camera","focus","flash"].contains(id) {
        let start: (Bool) -> Void = { [weak self] granted in
          DispatchQueue.main.async {
            guard let self = self, token == self.generation else { result(["status":"interrupted","message":"Test cancelled."]); return }
            guard granted else { result(["status":"permission","message":"Permission Required. Allow Camera access in Settings."]); return }
            self.camera.start(id, completion: result)
          }
        }
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined { AVCaptureDevice.requestAccess(for: .video, completionHandler: start) }
        else { start(AVCaptureDevice.authorizationStatus(for: .video) == .authorized) }
      } else if ["speaker","earpiece","microphone"].contains(id) {
        let start: (Bool) -> Void = { [weak self] granted in
          DispatchQueue.main.async {
            guard let self = self, token == self.generation else { result(["status":"interrupted","message":"Test cancelled."]); return }
            guard granted else { result(["status":"permission","message":"Permission Required. Allow Microphone access in Settings."]); return }
            do { try self.audio.prepare(id); result(["status":"ready","message": id == "earpiece" ? "Hold the top receiver to your ear at a comfortable volume. Check the actual audio route below; disconnect external audio devices." : "Use a comfortable volume and listen carefully."]) }
            catch { result(["status":"unavailable","message":"Audio could not start. Please try again."]) }
          }
        }
        if id == "microphone" { AVAudioSession.sharedInstance().requestRecordPermission(start) } else { start(true) }
      } else { result(sensors.start(id)) }
    case "play": perform(result) { try audio.play() }
    case "stopPlayback": audio.stopPlayback(); result(nil)
    case "record": perform(result) { try audio.record() }
    case "stopRecording": audio.stopRecording(); result(nil)
    case "haptic": sensors.haptic(); result(nil)
    case "torch": camera.torch { success in
      if success { result(nil) } else { result(FlutterError(code:"torch",message:"Torch is unavailable. Let the phone cool down and retry.",details:nil)) }
    }
    default: result(FlutterMethodNotImplemented)
    }
  }
  private func perform(_ result: FlutterResult, action: () throws -> Void) {
    do { try action(); result(nil) } catch { result(FlutterError(code:"diagnostic",message:error.localizedDescription,details:nil)) }
  }
  private func stop() { generation += 1; active = ""; audio.stop(); camera.stop(); sensors.stop() }
}
