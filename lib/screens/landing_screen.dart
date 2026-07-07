import 'package:flutter/material.dart';
import '../widgets/heat_shift_button.dart';
import 'scan_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // Logo / branding
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8642A).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.thermostat,
                  color: Color(0xFFE8642A),
                  size: 72,
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Heat Shift',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Installer App',
                style: TextStyle(
                  color: Color(0xFFE8642A),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 48),

              // Instructions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: Column(
                  children: [
                    _Step(
                      number: '1',
                      text: 'Hold both buttons on the control box for 5 seconds',
                    ),
                    const SizedBox(height: 16),
                    _Step(
                      number: '2',
                      text: 'A 4-digit PIN will appear on the device screen',
                    ),
                    const SizedBox(height: 16),
                    _Step(
                      number: '3',
                      text: 'Tap Search below to find the device, then enter the PIN',
                    ),
                  ],
                ),
              ),

              const Spacer(),

              HeatShiftButton(
                label: 'Search for Devices',
                icon: Icons.bluetooth_searching,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScanScreen()),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String text;

  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Color(0xFFE8642A),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}