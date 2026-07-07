import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/device_model.dart';
import '../services/session_service.dart';
import '../widgets/heat_shift_button.dart';
import 'dashboard_screen.dart';

class PinScreen extends StatefulWidget {
  final HeatShiftDevice device;
  const PinScreen({super.key, required this.device});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final _pinController = TextEditingController();
  final _session = SessionService();
  bool _isVerifying = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _verify() {
    final pin = _pinController.text.trim();
    if (pin.length != 4) {
      setState(() => _error = 'PIN must be 4 digits');
      return;
    }
    setState(() {
      _isVerifying = true;
      _error = null;
    });
    _session.authenticate(pin);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardScreen(device: widget.device),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Enter PIN',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              widget.device.name,
              style: const TextStyle(
                color: Color(0xFFE8642A),
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Connected',
              style: TextStyle(color: Color(0xFF4CAF50), fontSize: 13),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE8642A).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                color: Color(0xFFE8642A),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Enter the 4-digit PIN\nshown on the device screen',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              autofocus: true,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w700,
                letterSpacing: 16,
              ),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFFE8642A), width: 2),
                ),
                errorText: _error,
                errorStyle: const TextStyle(color: Colors.redAccent),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: (_) => _verify(),
            ),
            const SizedBox(height: 24),
            HeatShiftButton(
              label: 'Confirm PIN',
              isLoading: _isVerifying,
              onPressed: _verify,
              icon: Icons.check,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}