import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/device/device_format.dart';

class StorageUsageBar extends StatelessWidget {
  const StorageUsageBar({
    super.key,
    required this.totalBytes,
    required this.availableBytes,
  });
  final int? totalBytes;
  final int? availableBytes;
  @override
  Widget build(BuildContext context) {
    final valid =
        totalBytes != null && totalBytes! > 0 && availableBytes != null;
    final used = valid
        ? (totalBytes! - availableBytes!).clamp(0, totalBytes!)
        : null;
    final fraction = valid ? used! / totalBytes! : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 9,
              color: AppColors.blue,
              backgroundColor: Theme.of(context).dividerColor,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Used  ${DeviceFormat.bytes(used)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Text(
                'Available  ${DeviceFormat.bytes(availableBytes)}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
