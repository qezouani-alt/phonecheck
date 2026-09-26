import Flutter
import UIKit

/// Atomic, device-local storage. A failed read never replaces existing reports.
final class ReportChannel {
  private let channel: FlutterMethodChannel
  private let queue = DispatchQueue(label: "com.phonecheck.report-storage")
  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "com.phonecheck/reports", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      if call.method == "share" {
        guard let args = call.arguments as? [String: Any], let text = args["text"] as? String,
              let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first(where: { $0.activationState == .foregroundActive }),
              var presenter = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
          result(FlutterError(code: "unavailable", message: "Sharing is unavailable.", details: nil)); return
        }
        while let presented = presenter.presentedViewController { presenter = presented }
        let activity = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        activity.popoverPresentationController?.sourceView = presenter.view
        activity.popoverPresentationController?.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 1, height: 1)
        presenter.present(activity, animated: true) { result(nil) }
        return
      }
      if call.method == "openUrl" {
        guard let args = call.arguments as? [String: Any],
              let text = args["url"] as? String,
              let url = URL(string: text) else {
          result(FlutterError(code: "invalid_url", message: "The App Store link is unavailable.", details: nil)); return
        }
        UIApplication.shared.open(url, options: [:]) { opened in
          opened ? result(nil) : result(FlutterError(code: "unavailable", message: "The App Store could not be opened.", details: nil))
        }
        return
      }
      guard call.method == "read" || call.method == "write" else { result(FlutterMethodNotImplemented); return }
      self.queue.async {
        do {
          let directory = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("PhoneCheck", isDirectory: true)
          try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
          let url = directory.appendingPathComponent("reports-v1.json")
          if call.method == "read" {
            let text = FileManager.default.fileExists(atPath: url.path) ? try String(contentsOf: url, encoding: .utf8) : "[]"
            DispatchQueue.main.async { result(text) }
          } else {
            guard let args = call.arguments as? [String: Any], let text = args["json"] as? String,
                  let data = text.data(using: .utf8), (try JSONSerialization.jsonObject(with: data)) is [Any] else {
              throw NSError(domain: "PhoneCheck", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid report data."])
            }
            try data.write(to: url, options: [.atomic, .completeFileProtectionUnlessOpen])
            DispatchQueue.main.async { result(nil) }
          }
        } catch {
          DispatchQueue.main.async { result(FlutterError(code: "storage", message: "Local report storage failed. Your existing reports have not been replaced.", details: nil)) }
        }
      }
    }
  }
}
