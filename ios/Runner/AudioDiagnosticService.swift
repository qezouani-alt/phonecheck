import AVFoundation

final class AudioDiagnosticService: NSObject, AVAudioRecorderDelegate {
  private var player: AVAudioPlayer?
  private var recorder: AVAudioRecorder?
  private var recordingURL: URL?
  private var recordingStarted: Date?
  private(set) var recordingCompleted = false
  private var recordingDuration: TimeInterval = 0
  private(set) var playbackStarted = false
  private var peak: Float = -160
  private var errorMessage: String?
  private var kind = ""
  func prepare(_ kind: String) throws {
    stop()
    self.kind = kind
    let session = AVAudioSession.sharedInstance()
    if kind == "earpiece" || kind == "microphone" {
      try session.setCategory(.playAndRecord, mode: kind == "earpiece" ? .voiceChat : .default, options: kind == "microphone" ? [.defaultToSpeaker] : [])
    } else { try session.setCategory(.playback, mode: .default) }
    try session.setActive(true)
  }
  func play() throws {
    let url: URL?
    if kind == "microphone" { url = recordingCompleted ? recordingURL : nil }
    else { url = Bundle.main.url(forResource: "diagnostic-tone", withExtension: "wav") }
    guard let url = url else { throw NSError(domain: "Audio", code: 1, userInfo: [NSLocalizedDescriptionKey: "No recording or test sound is available."]) }
    player?.stop()
    player = try AVAudioPlayer(contentsOf: url)
    player?.volume = 0.7
    guard player?.play() == true else { throw NSError(domain: "Audio", code: 2, userInfo: [NSLocalizedDescriptionKey: "Playback could not start."]) }
    playbackStarted = true
  }
  
  func stopPlayback() {
    player?.stop()
    playbackStarted = false
  }
  func record() throws {
    player?.stop(); recorder?.stop()
    recordingCompleted = false; recordingDuration = 0; peak = -160; errorMessage = nil; playbackStarted = false
    if let url = recordingURL { try? FileManager.default.removeItem(at: url) }
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("phonecheck-\(UUID().uuidString).m4a")
    recordingURL = url
    let recorder = try AVAudioRecorder(url: url, settings: [AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 44100, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue])
    self.recorder = recorder; recorder.delegate = self; recorder.isMeteringEnabled = true
    guard recorder.record(forDuration: 5) else { throw NSError(domain: "Audio", code: 3, userInfo: [NSLocalizedDescriptionKey: "Recording could not start."]) }
    recordingStarted = Date()
  }
  func stopRecording() {
    if let recorder = recorder, recorder.isRecording { recordingDuration = recorder.currentTime; recorder.stop() }
  }
  func sample() -> [String: Any] {
    recorder?.updateMeters()
    let active = recorder?.isRecording == true
    if active { peak = max(peak, recorder?.peakPower(forChannel: 0) ?? -160); recordingDuration = recorder?.currentTime ?? 0 }
    var data: [String: Any] = ["Audio route": AVAudioSession.sharedInstance().currentRoute.outputs.map { $0.portName }.joined(separator: ", "),
      "playing": player?.isPlaying == true, "recording": active, "elapsed": min(5, recordingDuration),
      "level": active ? pow(10.0, Double(recorder?.averagePower(forChannel: 0) ?? -160) / 20.0) : 0,
      "Recording completed": recordingCompleted, "Playback started": playbackStarted]
    if recordingStarted != nil { data["Recorded duration (s)"] = (recordingDuration * 10).rounded() / 10; data["Peak level (dBFS)"] = peak }
    if let error = errorMessage { data["error"] = error }
    return data
  }
  func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
    recordingCompleted = flag && recordingDuration > 0
    if flag, let started = recordingStarted { recordingDuration = min(5, max(recordingDuration, Date().timeIntervalSince(started))) }
    if !flag { errorMessage = "Recording was interrupted. Please try again." }
  }
  func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) { errorMessage = "Recording failed. Please try again."; recordingCompleted = false }
  func stop() {
    player?.stop(); player = nil
    recorder?.delegate = nil; recorder?.stop(); recorder = nil
    if let url = recordingURL { try? FileManager.default.removeItem(at: url) }
    recordingURL = nil; recordingStarted = nil; recordingCompleted = false; recordingDuration = 0; playbackStarted = false
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }
}
