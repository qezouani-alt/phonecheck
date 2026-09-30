import CoreMotion
import CoreLocation
import CoreHaptics
import UIKit

final class SensorDiagnosticService: NSObject, CLLocationManagerDelegate {
  private let motion = CMMotionManager()
  private var headingManager: CLLocationManager?
  private var data: [String: Any] = [:]
  private var firstHeading: Double?
  private var nearSeen = false
  private var kind = ""
  func start(_ id: String) -> [String: Any] {
    stop(); kind = id; data = [:]; firstHeading = nil; nearSeen = false
    switch id {
    case "accelerometer":
      guard motion.isAccelerometerAvailable else { return unavailable("Accelerometer is unavailable.") }
      motion.accelerometerUpdateInterval = 0.1
      motion.startAccelerometerUpdates(to: .main) { [weak self] sample, error in
        guard let self = self, self.kind == id else { return }
        if error != nil { self.data = ["error": "Motion data is unavailable. Check Motion & Fitness access in Settings."]; return }
        if let a = sample?.acceleration { self.data = ["X (g)": a.x, "Y (g)": a.y, "Z (g)": a.z] }
      }
    case "gyroscope":
      guard motion.isGyroAvailable && motion.isDeviceMotionAvailable else { return unavailable("Gyroscope attitude data is unavailable.") }
      motion.deviceMotionUpdateInterval = 0.1
      motion.startDeviceMotionUpdates(to: .main) { [weak self] sample, error in
        guard let self = self, self.kind == id else { return }
        if error != nil { self.data = ["error": "Motion data is unavailable. Check Motion & Fitness access in Settings."]; return }
        if let a = sample?.attitude { self.data = ["Pitch (°)": a.pitch*180 / .pi, "Roll (°)": a.roll*180 / .pi, "Yaw (°)": a.yaw*180 / .pi] }
      }
    case "compass":
      guard CLLocationManager.headingAvailable() else { return unavailable("Compass is unavailable.") }
      let manager = CLLocationManager(); headingManager = manager; manager.delegate = self; manager.headingFilter = 1
      if manager.authorizationStatus == .notDetermined { manager.requestWhenInUseAuthorization() }
      else { locationManagerDidChangeAuthorization(manager) }
    case "proximity":
      UIDevice.current.isProximityMonitoringEnabled = true
      guard UIDevice.current.isProximityMonitoringEnabled else { return unavailable("Proximity monitoring is unavailable.") }
      NotificationCenter.default.addObserver(self, selector: #selector(proximityChanged), name: UIDevice.proximityStateDidChangeNotification, object: nil)
      data = ["Proximity": "Waiting"]
    case "haptics":
      guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return unavailable("Haptic feedback is unavailable on this device.") }
    default: return unavailable("Sensor is unavailable.")
    }
    return ["status": "ready", "message": "Observe the response, then record your result."]
  }
  func haptic() {
    let generator = UIImpactFeedbackGenerator(style: .heavy); generator.prepare(); generator.impactOccurred()
    data["Haptic triggers"] = (data["Haptic triggers"] as? Int ?? 0) + 1
  }
  @objc private func proximityChanged() {
    let near = UIDevice.current.proximityState
    if near { nearSeen = true }
    data = ["Proximity": near ? "Object Detected" : "Object Removed", "Object detected during test": nearSeen]
  }
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    switch manager.authorizationStatus {
    case .authorizedAlways, .authorizedWhenInUse: manager.startUpdatingHeading()
    case .denied, .restricted: data = ["error": "Permission Required. Allow Location access in Settings to use this compass test."]
    default: break
    }
  }
  func locationManager(_ manager: CLLocationManager, didUpdateHeading heading: CLHeading) {
    guard heading.headingAccuracy >= 0 else { data = ["error": "Compass reading is unreliable. Move away from magnets and retry."]; return }
    let value = heading.magneticHeading
    if firstHeading == nil { firstHeading = value }
    let delta = abs(value - (firstHeading ?? value))
    let changed = min(delta,360-delta) > 5 || data["Heading changed"] as? Bool == true
    data = ["Magnetic heading (°)": value, "Heading accuracy (°)": heading.headingAccuracy, "Heading changed": changed]
  }
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { data = ["error": "Compass reading is unavailable."] }
  func sample() -> [String: Any] { data }
  func stop() {
    kind = ""; motion.stopAccelerometerUpdates(); motion.stopDeviceMotionUpdates()
    headingManager?.stopUpdatingHeading(); headingManager?.delegate = nil; headingManager = nil
    NotificationCenter.default.removeObserver(self); UIDevice.current.isProximityMonitoringEnabled = false
  }
  private func unavailable(_ message: String) -> [String: Any] { ["status": "unavailable", "message": message] }
}
