import 'package:flutter/material.dart';
import '../services/ble_service.dart';
import '../services/session_service.dart';
import '../widgets/section_header.dart';
import '../widgets/segmented_option.dart';

class SystemModeScreen extends StatefulWidget {
  const SystemModeScreen({super.key});

  @override
  State<SystemModeScreen> createState() => _SystemModeScreenState();
}

class _SystemModeScreenState extends State<SystemModeScreen> {
  final _ble = BleService();
  final _session = SessionService();

  bool _loading = true;
  String? _loadError;
  String _currentMode = 'cool_down';
  String _selectedMode = 'cool_down';

  bool _sending = false;
  String? _result;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentMode();
  }

  Future<void> _loadCurrentMode() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final settings = await _ble.readCurrentSettings();
    if (!mounted) return;
    if (settings == null) {
      setState(() {
        _loading = false;
        _loadError = "Couldn't read the device's current mode.";
      });
      return;
    }
    final mode = settings['system_mode'] as String? ?? 'cool_down';
    setState(() {
      _loading = false;
      _currentMode = mode;
      _selectedMode = mode;
    });
  }

  Future<void> _onSelect(int index) async {
    final newMode = index == 0 ? 'cool_down' : 'heat_up';
    if (newMode == _currentMode) return;

    setState(() => _selectedMode = newMode);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Restart Required',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Switching to ${newMode == 'cool_down' ? 'Cool Down' : 'Heat Up'} '
              'restarts the control box. It will be offline for about 30 '
              'seconds, and you\'ll need to hold both buttons on the device '
              'to pair again afterward.',
          style: const TextStyle(color: Color(0xFFAAAAAA), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restart & Switch',
                style: TextStyle(
                    color: Color(0xFFE8642A), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      setState(() => _selectedMode = _currentMode);
      return;
    }

    await _applyModeChange(newMode);
  }

  Future<void> _applyModeChange(String newMode) async {
    setState(() {
      _sending = true;
      _result = null;
      _success = false;
    });

    try {
      final status = await _ble.sendConfig(
        pin: _session.pin!,
        config: {'system_mode': newMode},
      );

      if (!mounted) return;

      if (status == 'config_ok') {
        setState(() {
          _sending = false;
          _success = true;
          _result = 'Mode changed. The control box is restarting - '
              'this takes about 30 seconds.';
        });
        // The Pi is rebooting - this session is about to be unusable
        // regardless, so head back to the start rather than strand the
        // user on a screen that can no longer do anything.
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      } else if (status.startsWith('error:invalid_pin')) {
        setState(() {
          _sending = false;
          _result = 'Invalid PIN. Please reconnect and re-enter the PIN.';
          _selectedMode = _currentMode;
        });
        _session.clearSession();
      } else {
        setState(() {
          _sending = false;
          _result = 'Error: $status';
          _selectedMode = _currentMode;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _result = 'Error: $e';
        _selectedMode = _currentMode;
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
          'System Mode',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
            child: CircularProgressIndicator(color: Color(0xFFE8642A)))
            : _loadError != null
            ? _buildLoadError()
            : _buildContent(),
      ),
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text(_loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFAAAAAA))),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _loadCurrentMode,
              child: const Text('Retry',
                  style: TextStyle(color: Color(0xFFE8642A))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'SYSTEM MODE', icon: Icons.settings),
          const SizedBox(height: 8),
          const Text(
            'Changing this restarts the control box, so it lives on its '
                'own screen separate from other settings.',
            style: TextStyle(
                color: Color(0xFF888888), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          IgnorePointer(
            ignoring: _sending,
            child: Opacity(
              opacity: _sending ? 0.5 : 1.0,
              child: SegmentedOption(
                options: const ['Cool Down', 'Heat Up'],
                selected: _selectedMode == 'cool_down' ? 0 : 1,
                onChanged: _onSelect,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_sending)
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFFE8642A)),
                ),
                SizedBox(width: 12),
                Text('Applying...',
                    style: TextStyle(color: Color(0xFFAAAAAA))),
              ],
            ),
          if (_result != null)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: _success
                    ? Colors.green.shade900.withOpacity(0.3)
                    : Colors.red.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color:
                  _success ? Colors.green.shade700 : Colors.red.shade700,
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
        ],
      ),
    );
  }
}