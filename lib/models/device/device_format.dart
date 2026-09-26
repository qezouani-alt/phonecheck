abstract final class DeviceFormat {
  static String text(String? value) =>
      value == null || value.isEmpty ? 'Unavailable' : value;
  static String bytes(int? bytes) {
    if (bytes == null || bytes < 0) return 'Unavailable';
    final gb = bytes / 1000000000;
    if (gb >= 1) {
      return '${gb.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} GB';
    }
    final mb = bytes / 1000000;
    return '${mb.toStringAsFixed(1)} MB';
  }

  static String percent(int? value) =>
      value == null ? 'Unavailable' : '$value%';
  static String onOff(bool? value) => value == null
      ? 'Unavailable'
      : value
      ? 'On'
      : 'Off';
  static String yesNo(bool? value) => value == null
      ? 'Unavailable'
      : value
      ? 'Yes'
      : 'No';
  static String available(bool? value) => value == null
      ? 'Unavailable'
      : value
      ? 'Available'
      : 'Unavailable';
  static String supported(bool? value) => value == null
      ? 'Unavailable'
      : value
      ? 'Supported'
      : 'Unsupported';
}
