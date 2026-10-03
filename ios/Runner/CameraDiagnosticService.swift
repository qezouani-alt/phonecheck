import Flutter
import AVFoundation
import UIKit

final class CameraDiagnosticService {
  let session = AVCaptureSession()
  private let queue = DispatchQueue(label: "com.phonecheck.camera")
  private var device: AVCaptureDevice?
  private var generation = 0
  private var state: [String: Any] = [:]
  func start(_ id: String, completion: @escaping ([String: Any]) -> Void) {
    generation += 1
    let token = generation
    queue.async {
      do {
        self.session.beginConfiguration()
        self.session.inputs.forEach { self.session.removeInput($0) }
        let position: AVCaptureDevice.Position = id == "front_camera" ? .front : .back
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
          self.session.commitConfiguration()
          DispatchQueue.main.async { completion(["status": "unavailable", "message": "This camera is unavailable."]) }; return
        }
        let input: AVCaptureDeviceInput
        do { input = try AVCaptureDeviceInput(device: device) }
        catch { self.session.commitConfiguration(); throw error }
        guard self.session.canAddInput(input) else {
          self.session.commitConfiguration(); throw NSError(domain: "Camera", code: 1)
        }
        self.session.addInput(input); self.session.sessionPreset = .high; self.device = device
        self.session.commitConfiguration()
        self.session.startRunning()
        let torchAvailable = device.hasTorch && device.isTorchAvailable
        DispatchQueue.main.async {
          guard self.generation == token else { completion(["status": "interrupted", "message": "Camera test cancelled."]); return }
          self.state = ["Camera": device.localizedName, "Preview started": self.session.isRunning, "torch": false, "Focus taps": 0]
          if id == "flash" && !torchAvailable { completion(["status": "unavailable", "message": "Torch is unavailable on this camera."]) }
          else if !self.session.isRunning { completion(["status": "unavailable", "message": "Camera preview could not start."]) }
          else { completion(["status": "ready", "message": "Inspect the live preview. Tap an object to focus."]) }
        }
      } catch { DispatchQueue.main.async { completion(["status": "unavailable", "message": "Camera could not start. Close other camera apps and retry."]) } }
    }
  }
  func focus(_ point: CGPoint) {
    queue.async {
      guard let device = self.device, device.isFocusPointOfInterestSupported, device.isFocusModeSupported(.autoFocus) else { return }
      do {
        try device.lockForConfiguration(); device.focusPointOfInterest = point; device.focusMode = .autoFocus; device.unlockForConfiguration()
        DispatchQueue.main.async { self.state["Focus taps"] = (self.state["Focus taps"] as? Int ?? 0) + 1 }
      } catch { }
    }
  }
  func torch(completion: @escaping (Bool) -> Void) {
    queue.async {
      guard let device = self.device, device.hasTorch, device.isTorchAvailable else { DispatchQueue.main.async { completion(false) }; return }
      do {
        try device.lockForConfiguration()
        let enabled = device.torchMode != .on
        if enabled { try device.setTorchModeOn(level: 0.5) } else { device.torchMode = .off }
        device.unlockForConfiguration()
        DispatchQueue.main.async { self.state["torch"] = enabled; self.state["Torch activated"] = true; completion(true) }
      } catch { device.unlockForConfiguration(); DispatchQueue.main.async { completion(false) } }
    }
  }
  func sample() -> [String: Any] { state }
  func stop() {
    generation += 1
    queue.async {
      if let device = self.device, device.hasTorch { try? device.lockForConfiguration(); device.torchMode = .off; device.unlockForConfiguration() }
      if self.session.isRunning { self.session.stopRunning() }
      self.session.beginConfiguration(); self.session.inputs.forEach { self.session.removeInput($0) }; self.session.commitConfiguration()
      self.device = nil
    }
    state = [:]
  }
}
private final class CameraPreviewView: UIView {
  override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
  var preview: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}
private final class CameraPlatformView: NSObject, FlutterPlatformView {
  private let preview = CameraPreviewView()
  private let service: CameraDiagnosticService
  private let focusRing = UIView()
  init(frame: CGRect, service: CameraDiagnosticService) {
    self.service = service
    super.init()
    preview.frame = frame; preview.preview.session = service.session; preview.preview.videoGravity = .resizeAspectFill
    preview.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped(_:))))
    focusRing.layer.borderWidth = 2; focusRing.layer.borderColor = UIColor.systemYellow.cgColor; focusRing.isHidden = true; focusRing.isUserInteractionEnabled = false
    preview.addSubview(focusRing)
    preview.accessibilityLabel = "Live camera preview. Tap an object to focus."
  }
  @objc private func tapped(_ gesture: UITapGestureRecognizer) {
    let point = gesture.location(in: preview)
    service.focus(preview.preview.captureDevicePointConverted(fromLayerPoint: point))
    focusRing.frame = CGRect(x: point.x-25, y: point.y-25, width: 50, height: 50); focusRing.isHidden = false
    DispatchQueue.main.asyncAfter(deadline: .now()+0.8) { [weak self] in self?.focusRing.isHidden = true }
  }
  func view() -> UIView { preview }
}
final class CameraPreviewFactory: NSObject, FlutterPlatformViewFactory {
  private let service: CameraDiagnosticService
  init(service: CameraDiagnosticService) { self.service = service }
  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    CameraPlatformView(frame: frame, service: service)
  }
}
