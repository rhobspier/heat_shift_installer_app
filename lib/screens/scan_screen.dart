import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/device_model.dart';
import '../services/ble_service.dart';
import '../widgets/heat_shift_button.dart';
import 'pin_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final BleService _ble = BleService();
  List<HeatShiftDevice> _devices = [];
  bool _scanning = false;
  bool _connecting = false;
  String? _connectingId;
  String? _error;
  bool _permissionsGranted = false;
  StreamSubscription? _scanSub;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _ble.stopScan();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final denied = statuses.values
        .any((s) => s.isDenied || s.isPermanentlyDenied);

    setState(() {
      _permissionsGranted = !denied;
      if (denied) {
        _error =
        'Bluetooth and location permissions are required to scan for devices.';
      }
    });
  }

  Future<void> _startScan() async {
    if (!_permissionsGranted) {
      await _requestPermissions();
      if (!_permissionsGranted) return;
    }

    setState(() {
      _scanning = true;
      _devices = [];
      _error = null;
    });

    _scanSub?.cancel();
    _scanSub = _ble.scanForDevices().listen(
          (devices) => setState(() => _devices = devices),
      onError: (e) => setState(() {
        _error = 'Scan error: $e';
        _scanning = false;
      }),
      onDone: () => setState(() => _scanning = false),
    );
  }

  Future<void> _connectToDevice(HeatShiftDevice device) async {
    setState(() {
      _connecting = true;
      _connectingId = device.id;
      _error = null;
    });

    await _ble.stopScan();
    _scanSub?.cancel();
    setState(() => _scanning = false);

    try {
      await _ble.connect(device);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PinScreen(device: device)),
      );
      setState(() {
        _connecting = false;
        _connectingId = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Connection failed. Make sure the device is in pairing mode.\n\nDetails: $e';
        _connecting = false;
        _connectingId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Find Device',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_scanning)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                  AlwaysStoppedAnimation(Color(0xFFE8642A)),
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade700),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.redAccent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ),
                  ],
                ),
              ),

            // Status text
            if (_scanning || _devices.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _devices.isEmpty
                      ? 'Scanning for Heat Shift devices...'
                      : '${_devices.length} device${_devices.length == 1 ? '' : 's'} found',
                  style: const TextStyle(
                      color: Color(0xFFAAAAAA), fontSize: 13),
                ),
              ),

            // Device list
            Expanded(
              child: _devices.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _scanning
                          ? Icons.bluetooth_searching
                          : Icons.bluetooth_disabled,
                      size: 72,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _scanning
                          ? 'Looking for Heat Shift devices...'
                          : 'Tap Scan to search for devices',
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14),
                    ),
                  ],
                ),
              )
                  : ListView.separated(
                itemCount: _devices.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 8),
                itemBuilder: (_, i) => _DeviceTile(
                  device: _devices[i],
                  isConnecting:
                  _connectingId == _devices[i].id,
                  onTap: _connecting
                      ? null
                      : () => _connectToDevice(_devices[i]),
                ),
              ),
            ),

            const SizedBox(height: 16),
            HeatShiftButton(
              label: _scanning ? 'Scanning...' : 'Scan for Devices',
              isLoading: _scanning,
              onPressed: _scanning ? null : _startScan,
              icon: Icons.bluetooth_searching,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final HeatShiftDevice device;
  final bool isConnecting;
  final VoidCallback? onTap;

  const _DeviceTile({
    required this.device,
    required this.isConnecting,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isConnecting
                ? const Color(0xFFE8642A)
                : const Color(0xFF333333),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8642A).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.thermostat,
                  color: Color(0xFFE8642A), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${device.signalStrength} signal  •  ${device.rssi} dBm',
                    style: const TextStyle(
                        color: Color(0xFF888888), fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isConnecting)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                  AlwaysStoppedAnimation(Color(0xFFE8642A)),
                ),
              )
            else
              const Icon(Icons.chevron_right,
                  color: Color(0xFF555555)),
          ],
        ),
      ),
    );
  }
}