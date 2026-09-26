import 'package:flutter/material.dart';

import '../models/test_category.dart';
import '../models/test_item.dart';

abstract final class MockTestData {
  static const categories = <TestCategory>[
    TestCategory(
      id: 'screen',
      title: 'Screen',
      icon: Icons.phone_iphone_rounded,
      items: [
        TestItem(
          id: 'touch',
          title: 'Touchscreen Grid Test',
          description: 'Drag your finger across the entire screen.',
          icon: Icons.grid_on_rounded,
        ),
        TestItem(
          id: 'multi',
          title: 'Multi-Touch Test',
          description: 'Place multiple fingers on the screen.',
          icon: Icons.pan_tool_alt_rounded,
        ),
        TestItem(
          id: 'pixel',
          title: 'Dead Pixel Test',
          description: 'Look for dots or lines that stay a different color.',
          icon: Icons.color_lens_outlined,
        ),
        TestItem(
          id: 'oled',
          title: 'OLED / Burn-In Test',
          description: 'Check for uneven areas or ghost images.',
          icon: Icons.gradient_rounded,
        ),
        TestItem(
          id: 'brightness',
          title: 'Brightness Check',
          description: 'Check that brightness changes smoothly.',
          icon: Icons.brightness_6_rounded,
        ),
      ],
    ),
    TestCategory(
      id: 'audio',
      title: 'Audio',
      icon: Icons.volume_up_rounded,
      items: [
        TestItem(
          id: 'speaker',
          title: 'Main Speaker',
          description: 'Play a sample and listen for distortion.',
          icon: Icons.speaker_rounded,
        ),
        TestItem(
          id: 'earpiece',
          title: 'Earpiece',
          description: 'Listen for clear sound from the earpiece.',
          icon: Icons.hearing_rounded,
        ),
        TestItem(
          id: 'microphone',
          title: 'Microphone',
          description: 'Record and play back your voice.',
          icon: Icons.mic_rounded,
        ),
      ],
    ),
    TestCategory(
      id: 'camera',
      title: 'Cameras',
      icon: Icons.camera_alt_rounded,
      items: [
        TestItem(
          id: 'front_camera',
          title: 'Front Camera',
          description: 'Look for a clear, even image.',
          icon: Icons.camera_front_rounded,
        ),
        TestItem(
          id: 'rear_camera',
          title: 'Rear Camera',
          description: 'Check the image and lens condition.',
          icon: Icons.camera_rear_rounded,
        ),
        TestItem(
          id: 'focus',
          title: 'Focus Test',
          description: 'Check whether the camera focuses correctly.',
          icon: Icons.center_focus_strong_rounded,
        ),
        TestItem(
          id: 'flash',
          title: 'Flash Test',
          description: 'Check that the flash illuminates evenly.',
          icon: Icons.flash_on_rounded,
        ),
      ],
    ),
    TestCategory(
      id: 'sensors',
      title: 'Sensors',
      icon: Icons.sensors_rounded,
      items: [
        TestItem(
          id: 'accelerometer',
          title: 'Accelerometer',
          description: 'Tilt the iPhone left and right.',
          icon: Icons.screen_rotation_rounded,
        ),
        TestItem(
          id: 'gyroscope',
          title: 'Gyroscope',
          description: 'Rotate the iPhone slowly.',
          icon: Icons.rotate_right_rounded,
        ),
        TestItem(
          id: 'compass',
          title: 'Compass',
          description: 'Rotate the iPhone and check the heading.',
          icon: Icons.explore_rounded,
        ),
        TestItem(
          id: 'proximity',
          title: 'Proximity Sensor',
          description: 'Cover the top of the iPhone.',
          icon: Icons.sensors_off_rounded,
        ),
        TestItem(
          id: 'haptics',
          title: 'Haptics / Vibration',
          description: 'Check whether you feel the vibration.',
          icon: Icons.vibration_rounded,
        ),
      ],
    ),
    TestCategory(
      id: 'connectivity',
      title: 'Connectivity',
      icon: Icons.wifi_rounded,
      items: [
        TestItem(
          id: 'wifi',
          title: 'Wi-Fi',
          description:
              'Review the current network path and verify Wi-Fi browsing.',
          icon: Icons.wifi_rounded,
        ),
        TestItem(
          id: 'bluetooth',
          title: 'Bluetooth',
          description:
              'Check Bluetooth state, then verify an accessory in Settings.',
          icon: Icons.bluetooth_rounded,
        ),
        TestItem(
          id: 'gps',
          title: 'GPS / Location',
          description: 'Verify that location can be determined.',
          icon: Icons.location_on_rounded,
        ),
        TestItem(
          id: 'cellular',
          title: 'Cellular / SIM',
          description: 'Check SIM detection, signal, and mobile data.',
          icon: Icons.signal_cellular_alt_rounded,
        ),
      ],
    ),
    TestCategory(
      id: 'physical',
      title: 'Physical Inspection',
      icon: Icons.fact_check_rounded,
      items: [
        TestItem(
          id: 'side_button',
          title: 'Side Button',
          description: 'Press it and check for a firm click.',
          icon: Icons.smart_button_rounded,
        ),
        TestItem(
          id: 'volume_up',
          title: 'Volume Up',
          description: 'Press it and check for a firm, consistent response.',
          icon: Icons.volume_up_rounded,
        ),
        TestItem(
          id: 'volume_down',
          title: 'Volume Down',
          description: 'Press it and check for a firm, consistent response.',
          icon: Icons.volume_down_rounded,
        ),
        TestItem(
          id: 'charging_port',
          title: 'Charging Port',
          description:
              'Check for debris, looseness, damage, and intermittent charging.',
          icon: Icons.battery_charging_full_rounded,
        ),
        TestItem(
          id: 'face_id',
          title: 'Face ID / Touch ID',
          description: 'Open Settings or unlock the device to confirm Face ID or Touch ID works. This is a manual unlocking check.',
          icon: Icons.face_rounded,
        ),
        TestItem(
          id: 'front_condition',
          title: 'Front Camera Condition',
          description: 'Inspect the lens for scratches or debris.',
          icon: Icons.camera_front_rounded,
        ),
        TestItem(
          id: 'rear_condition',
          title: 'Rear Camera Condition',
          description: 'Inspect each rear lens.',
          icon: Icons.camera_rear_rounded,
        ),
        TestItem(
          id: 'screen_condition',
          title: 'Screen Condition',
          description: 'Check for cracks, scratches, and lifting.',
          icon: Icons.phone_iphone_rounded,
        ),
        TestItem(
          id: 'back_glass',
          title: 'Back Glass Condition',
          description: 'Check for cracks and separation.',
          icon: Icons.crop_portrait_rounded,
        ),
        TestItem(
          id: 'audio_condition',
          title: 'Speaker & Microphone Condition',
          description: 'Inspect openings for damage or debris.',
          icon: Icons.mic_rounded,
        ),
      ],
    ),
  ];
  static TestItem item(String id) => categories
      .expand((category) => category.items)
      .firstWhere((item) => item.id == id);
  static TestCategory categoryFor(String id) => categories.firstWhere(
    (category) => category.items.any((item) => item.id == id),
  );
}
