import 'package:flutter/material.dart';
import '../models/config_model.dart';
import '../services/ble_service.dart';
import '../services/session_service.dart';
import '../widgets/heat_shift_button.dart';
import '../widgets/section_header.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _ble = BleService();
  final _session = SessionService();
  final _config = HeatShiftConfig();
  bool _sending = false;
  String? _result;
  bool _success = false;

  Future<void> _sendConfig() async {
    setState(() {
      _sending = true;
      _result = null;
      _success = false;
    });

    try {
      final status = await _ble.sendConfig(
        pin: _session.pin!,
        config: {
          'fuel_type': _config.fuelType,
          'consumption_rate': _config.consumptionRate,
          'condenser_kw': _config.condenserKw,
          'activation_temp_heating': _config.activationTempHeating,
          'activation_temp_cooling': _config.activationTempCooling,
        },
      );

      setState(() {
        _sending = false;
        if (status == 'config_ok') {
          _success = true;
          _result = 'Configuration applied successfully!';
        } else if (status.startsWith('error:invalid_pin')) {
          _result = 'Invalid PIN. Please reconnect and re-enter the PIN.';
          _session.clearSession();
        } else {
          _result = 'Error: $status';
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
          'System Config',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fuel type (Heat Up only)
              if (_config.systemMode == 'heat_up') ...[
                const SectionHeader(
                    title: 'FUEL TYPE', icon: Icons.local_fire_department),
                _DropdownOption(
                  value: _config.fuelType,
                  items: const {
                    'oil': 'Oil',
                    'lpg': 'LPG / Propane',
                    'natural_gas': 'Natural Gas',
                    'heat_pump': 'Heat Pump',
                  },
                  onChanged: (v) => setState(() => _config.fuelType = v!),
                ),
                const SizedBox(height: 24),

                // Consumption rate
                SectionHeader(
                    title: _config.consumptionRateLabel.toUpperCase(),
                    icon: Icons.speed),
                _SliderOption(
                  value: _config.consumptionRate,
                  min: 0.1,
                  max: 10.0,
                  divisions: 99,
                  label: '${_config.consumptionRate.toStringAsFixed(1)}',
                  onChanged: (v) =>
                      setState(() => _config.consumptionRate = v),
                ),
                const SizedBox(height: 24),

                // Activation temp heating
                const SectionHeader(
                    title: 'ACTIVATION TEMP (HEATING)',
                    icon: Icons.thermostat),
                _SliderOption(
                  value: _config.activationTempHeating,
                  min: 50.0,
                  max: 100.0,
                  divisions: 100,
                  label: '${_config.activationTempHeating.toStringAsFixed(1)}°F',
                  onChanged: (v) =>
                      setState(() => _config.activationTempHeating = v),
                ),
              ],

              // Cool Down settings
              if (_config.systemMode == 'cool_down') ...[
                const SectionHeader(
                    title: 'CONDENSER SIZE', icon: Icons.ac_unit),
                _SliderOption(
                  value: _config.condenserKw,
                  min: 0.5,
                  max: 20.0,
                  divisions: 39,
                  label: '${_config.condenserKw.toStringAsFixed(1)} kW',
                  onChanged: (v) =>
                      setState(() => _config.condenserKw = v),
                ),
                const SizedBox(height: 24),

                const SectionHeader(
                    title: 'ACTIVATION TEMP (COOLING)',
                    icon: Icons.thermostat),
                _SliderOption(
                  value: _config.activationTempCooling,
                  min: 50.0,
                  max: 100.0,
                  divisions: 100,
                  label: '${_config.activationTempCooling.toStringAsFixed(1)}°F',
                  onChanged: (v) =>
                      setState(() => _config.activationTempCooling = v),
                ),
              ],

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
                        color: _success ? Colors.green : Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_result!,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ),
                    ],
                  ),
                ),

              HeatShiftButton(
                label: 'Apply Configuration',
                isLoading: _sending,
                onPressed: _sending ? null : _sendConfig,
                icon: Icons.check,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────

class _DropdownOption extends StatelessWidget {
  final String value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownOption({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF2A2A2A),
          style: const TextStyle(color: Colors.white, fontSize: 15),
          items: items.entries
              .map((e) => DropdownMenuItem(
            value: e.key,
            child: Text(e.value),
          ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SliderOption extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String label;
  final ValueChanged<double> onChanged;

  const _SliderOption({
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(min.toStringAsFixed(1),
                style: const TextStyle(
                    color: Color(0xFF666666), fontSize: 12)),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            Text(max.toStringAsFixed(1),
                style: const TextStyle(
                    color: Color(0xFF666666), fontSize: 12)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFFE8642A),
            inactiveTrackColor: const Color(0xFF333333),
            thumbColor: const Color(0xFFE8642A),
            overlayColor: const Color(0xFFE8642A).withOpacity(0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}