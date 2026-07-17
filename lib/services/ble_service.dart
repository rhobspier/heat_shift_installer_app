import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/device_model.dart';

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _wifiChar;
  BluetoothCharacteristic? _configChar;
  BluetoothCharacteristic? _statusChar;
  Timer? _keepaliveTimer;

  bool get isConnected => _connectedDevice != null;

  // ─────────────────────────────────────────────
  // Scanning
  // ─────────────────────────────────────────────

  Stream<List<HeatShiftDevice>> scanForDevices() async* {
    await FlutterBluePlus.stopScan();
    final Map<String, HeatShiftDevice> found = {};

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
      androidUsesFineLocation: true,
    );

    await for (final results in FlutterBluePlus.onScanResults) {
      for (final result in results) {
        if (HeatShiftDevice.isHeatShiftDevice(result)) {
          found[result.device.remoteId.str] = HeatShiftDevice(
            device: result.device,
            name: result.device.platformName,
            rssi: result.rssi,
          );
        }
      }
      yield found.values.toList();
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  // ─────────────────────────────────────────────
  // Connection
  // ─────────────────────────────────────────────

  Future<void> connect(HeatShiftDevice device) async {
    await disconnect();
    await device.device.connect(timeout: const Duration(seconds: 15));
    _connectedDevice = device.device;

    // Give the connection time to stabilize before discovering services
    await Future.delayed(const Duration(milliseconds: 800));
    await _discoverServices();

    // Read immediately (rather than waiting for the first keepalive
    // tick below) so the Pi clears its PIN screen as soon as a real
    // client shows up, instead of leaving it displayed for up to 30
    // more seconds for no reason.
    readStatus().catchError((_) => 'error:read_failed');

    // The Pi's session timeout resets on activity, but only counts
    // writes/reads it actually sees. A user who connects and just sits
    // reading a screen without submitting anything wouldn't generate
    // any of that - this periodic no-op status read exists purely to
    // keep the session alive for as long as the app stays connected,
    // regardless of whether the user is actively changing anything.
    _keepaliveTimer?.cancel();
    _keepaliveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      readStatus().catchError((_) => 'error:read_failed');
    });
  }

  Future<void> disconnect() async {
    _keepaliveTimer?.cancel();
    _keepaliveTimer = null;
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (_) {}
      _connectedDevice = null;
      _wifiChar = null;
      _configChar = null;
      _statusChar = null;
    }
  }

  Future<void> _discoverServices() async {
    if (_connectedDevice == null) return;

    // Retry service discovery up to 3 times — first attempt can fail on Android
    List<BluetoothService> services = [];
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        services = await _connectedDevice!.discoverServices();
        if (services.isNotEmpty) break;
      } catch (e) {
        if (attempt == 3) rethrow;
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    // Find our characteristics by UUID suffix
    for (final service in services) {
      for (final char in service.characteristics) {
        final uuid = char.uuid.str.toLowerCase();
        if (uuid.endsWith('def2')) _wifiChar = char;
        if (uuid.endsWith('def3')) _configChar = char;
        if (uuid.endsWith('def4')) _statusChar = char;
      }
    }

    if (_wifiChar == null || _configChar == null || _statusChar == null) {
      final found = services
          .expand((s) => s.characteristics)
          .map((c) => '...${c.uuid.str.toLowerCase().substring(c.uuid.str.length - 4)}')
          .join(', ');
      throw Exception(
          'Heat Shift characteristics not found.\n'
              'Found: $found\n\n'
              'Make sure the device is in pairing mode.');
    }
  }

  /// Recovers from a stale-GATT-handle write failure (commonly surfaces on
  /// Android as GATT_INVALID_HANDLE / android-code 1) by forcing a full
  /// disconnect + reconnect + service rediscovery. A single connect that
  /// merely calls discoverServices() again can still hand back
  /// characteristic objects bound to a cached handle table; tearing the
  /// physical connection down and reconnecting makes Android re-fetch the
  /// GATT table fresh from the peripheral instead of reusing a cached one.
  /// Returns true if recovery completed and the caller should retry its
  /// write once.
  Future<bool> _recoverFromWriteError(Object error) async {
    final device = _connectedDevice;
    if (device == null) return false;

    try {
      await device.disconnect();
    } catch (_) {}
    _wifiChar = null;
    _configChar = null;
    _statusChar = null;

    await Future.delayed(const Duration(milliseconds: 500));

    try {
      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = device;
      await Future.delayed(const Duration(milliseconds: 800));
      await _discoverServices();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Commands
  // ─────────────────────────────────────────────

  Future<String> sendWifiCredentials({
    required String pin,
    required String ssid,
    required String password,
  }) async {
    _ensureConnected();
    final payload = jsonEncode({
      'pin': pin,
      'ssid': ssid,
      'password': password,
    });

    try {
      await _wifiChar!.write(
        utf8.encode(payload),
        withoutResponse: false,
        timeout: 15,
      );
    } catch (e) {
      // Likely a stale GATT handle — reconnect fresh and retry once.
      if (!await _recoverFromWriteError(e)) rethrow;
      await _wifiChar!.write(
        utf8.encode(payload),
        withoutResponse: false,
        timeout: 15,
      );
    }

    // WiFi connection takes several seconds on the Pi
    await Future.delayed(const Duration(seconds: 8));
    return await readStatus();
  }

  Future<String> sendConfig({
    required String pin,
    required Map<String, dynamic> config,
  }) async {
    _ensureConnected();
    final payload = jsonEncode({'pin': pin, ...config});

    try {
      await _configChar!.write(
        utf8.encode(payload),
        withoutResponse: false,
        timeout: 10,
      );
    } catch (e) {
      // Likely a stale GATT handle — reconnect fresh and retry once.
      if (!await _recoverFromWriteError(e)) rethrow;
      await _configChar!.write(
        utf8.encode(payload),
        withoutResponse: false,
        timeout: 10,
      );
    }

    await Future.delayed(const Duration(seconds: 2));
    return await readStatus();
  }

  Future<String> readStatus() async {
    if (_statusChar == null) return 'error:no_status_char';
    try {
      final bytes = await _statusChar!.read(timeout: 10);
      return utf8.decode(bytes);
    } catch (e) {
      return 'error:read_failed';
    }
  }

  void _ensureConnected() {
    if (_connectedDevice == null) {
      throw Exception('Not connected to a device');
    }
  }

  Stream<BluetoothConnectionState> connectionStateStream() {
    if (_connectedDevice == null) {
      return Stream.value(BluetoothConnectionState.disconnected);
    }
    return _connectedDevice!.connectionState;
  }
}