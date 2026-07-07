import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/device_model.dart';
import '../services/ble_service.dart';
import '../services/session_service.dart';
import '../widgets/section_header.dart';
import 'wifi_screen.dart';
import 'config_screen.dart';

class DashboardScreen extends StatefulWidget {
  final HeatShiftDevice device;
  const DashboardScreen({super.key, required this.device});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _ble = BleService();
  final _session = SessionService();
  bool _connected = true;

  @override
  void initState() {
    super.initState();
    _ble.connectionStateStream().listen((state) {
      if (state == BluetoothConnectionState.disconnected && mounted) {
        setState(() => _connected = false);
        _session.clearSession();
        _showDisconnectedDialog();
      }
    });
  }

  void _showDisconnectedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Disconnected',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'The connection to the device was lost.',
          style: TextStyle(color: Color(0xFFAAAAAA)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: const Text('Back to Scan',
                style: TextStyle(color: Color(0xFFE8642A))),
          ),
        ],
      ),
    );
  }

  Future<void> _disconnect() async {
    await _ble.disconnect();
    _session.clearSession();
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.device.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _connected ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _connected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    color: _connected ? Colors.green : Colors.red,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _disconnect,
            child: const Text('Disconnect',
                style: TextStyle(color: Color(0xFFE8642A), fontSize: 13)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8642A), Color(0xFFB84E1E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.thermostat,
                      color: Colors.white, size: 36),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Heat Shift Installer',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Session active • PIN verified',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            const SectionHeader(title: 'INSTALLATION', icon: Icons.build),

            // WiFi setup card
            _DashboardCard(
              icon: Icons.wifi,
              title: 'WiFi Setup',
              subtitle: 'Connect the control box to the customer\'s network',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WifiScreen()),
              ),
            ),
            const SizedBox(height: 12),

            // System config card
            _DashboardCard(
              icon: Icons.settings,
              title: 'System Configuration',
              subtitle: 'Set system mode, fuel type, and activation temperature',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConfigScreen()),
              ),
            ),
            const SizedBox(height: 28),

            const SectionHeader(title: 'DEVICE INFO', icon: Icons.info_outline),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF333333)),
              ),
              child: Column(
                children: [
                  _InfoRow('Device Name', widget.device.name),
                  const Divider(color: Color(0xFF333333), height: 20),
                  _InfoRow('Device ID', widget.device.id),
                  const Divider(color: Color(0xFF333333), height: 20),
                  _InfoRow('Signal', '${widget.device.rssi} dBm (${widget.device.signalStrength})'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8642A).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFFE8642A), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: Color(0xFF888888), fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF555555)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFF888888), fontSize: 13)),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
