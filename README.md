# PhoneCheck

PhoneCheck is a Flutter app for guided used-iPhone inspection. The Home screen leads to a full inspection, a quick test, live Device Information, and saved report previews.

## Device Information

On iOS, a Swift service supplies publicly available device identity, battery, storage, memory, display, system state, camera and sensor capabilities, biometrics, network path, cellular technology, locale, and app information through `com.phonecheck/device`. Static information loads once; pull down on Device Information to refresh changing values. Bluetooth, location, camera and microphone permission checks, and biometric authentication run only after a deliberate tap. Capability availability is never shown as a passed diagnostic test.

The Model Specifications section uses a separate local reference catalog. Unknown identifiers safely show the generic device family and identifier. The app omits battery health, cycle count, serial and cellular identifiers, repair history, and other data unavailable through public iOS APIs. System uptime is intentionally omitted. Disk-space access is declared in `ios/Runner/PrivacyInfo.xcprivacy` with Apple's display-to-user reason `85F4.1`.

Screen Tests now enter edge-to-edge diagnostic mode after a brief instruction page. The touch grid and simultaneous multi-touch canvas occupy the full Flutter view; a disclosed two-finger hold temporarily reveals controls. Dead-pixel and OLED checks use full-screen solid colors with fading hints and long-press controls. Brightness uses a full-screen local preview with a temporary slider; it does not change iOS brightness. System UI is hidden during active diagnostics and restored on finish, cancel, or route exit. iOS-reserved gesture areas and hardware cutouts cannot be tested by the app. Results are user-selected observations, not automatic hardware-health claims. Starting a full inspection creates an in-memory session with a device-information snapshot and test results. Audio and later full-inspection categories currently show placeholders; Quick Test retains its existing guided UI. Reports are stored in memory for the current app session; Share copies a text summary to the clipboard and does not include disk-space data.

Run with `flutter run`. Verify with `flutter analyze`, `flutter test`, and `flutter build ios --simulator --no-codesign`.
