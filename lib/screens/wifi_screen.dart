import 'package:flutter/material.dart';
import '../services/ble_service.dart';
import '../services/session_service.dart';
import '../widgets/heat_shift_button.dart';
import '../widgets/section_header.dart';

class WifiScreen extends StatefulWidget {
  const WifiScreen({super.key});

  @override
  State<WifiScreen> createState() => _WifiScreenState();
}

class _WifiScreenState extends State<WifiScreen> {
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ble = BleService();
  final _session = SessionService();
  bool _sending = false;
  bool _passwordVisible = false;
  String? _result;
  bool _success = false;

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendCredentials() async {
    if (_ssidController.text.trim().isEmpty) {
      setState(() => _result = 'Please enter a network name (SSID)');
      return;
    }

    setState(() {
      _sending = true;
      _result = null;
      _success = false;
    });

    try {
      final status = await _ble.sendWifiCredentials(
        pin: _session.pin!,
        ssid: _ssidController.text.trim(),
        password: _passwordController.text,
      );

      setState(() {
        _sending = false;
        if (status == 'wifi_ok') {
          _success = true;
          _result = 'Connected to "${_ssidController.text.trim()}" successfully!';
        } else if (status.startsWith('error:invalid_pin')) {
          _result = 'Invalid PIN. Please go back and re-enter the PIN.';
          _session.clearSession();
        } else if (status.startsWith('error:wifi_failed')) {
          _result = 'WiFi connection failed. Check the network name and password.';
        } else {
          _result = 'Unexpected response: $status';
        }
      });
    } catch (e) {
      setState(() {
        _sending = false;
        _result = 'Error: $e';
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
          'WiFi Setup',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'NETWORK CREDENTIALS', icon: Icons.wifi),

              // Info box
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Color(0xFFE8642A), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Enter the customer\'s home WiFi details. The control box must be within range of the router.',
                        style: TextStyle(
                            color: Color(0xFFAAAAAA), fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),

              // SSID
              const Text('Network Name (SSID)',
                  style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: _ssidController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('e.g. HomeNetwork-5G'),
              ),
              const SizedBox(height: 16),

              // Password
              const Text('Password',
                  style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: !_passwordVisible,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('WiFi password').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: const Color(0xFF888888),
                    ),
                    onPressed: () =>
                        setState(() => _passwordVisible = !_passwordVisible),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Result
              if (_result != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: _success
                        ? Colors.green.shade900.withOpacity(0.3)
                        : Colors.red.shade900.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _success
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _success ? Icons.check_circle : Icons.error_outline,
                        color:
                        _success ? Colors.green : Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _result!,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              HeatShiftButton(
                label: _success ? 'Update WiFi' : 'Connect to WiFi',
                isLoading: _sending,
                onPressed: _sending ? null : _sendCredentials,
                icon: Icons.wifi,
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF555555)),
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
        const BorderSide(color: Color(0xFFE8642A), width: 1.5),
      ),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}