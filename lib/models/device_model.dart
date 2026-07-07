import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class HeatShiftDevice {
  final BluetoothDevice device;
  final String name;
  final int rssi;

  HeatShiftDevice({
    required this.device,
    required this.name,
    required this.rssi,
  });

  String get id => device.remoteId.str;

  // Signal strength as a human readable label
  String get signalStrength {
    if (rssi >= -60) return 'Excellent';
    if (rssi >= -70) return 'Good';
    if (rssi >= -80) return 'Fair';
    return 'Weak';
  }

  static bool isHeatShiftDevice(ScanResult result) {
    final name = result.device.platformName;
    return name.startsWith('HeatShift-');
  }
}
