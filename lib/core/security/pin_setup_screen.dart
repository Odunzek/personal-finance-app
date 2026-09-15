import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_lock_controller.dart';
import 'pin_vault.dart';

/// Settings flow to turn the PIN lock on (enter a new PIN twice to confirm)
/// or off (with the current PIN as proof, if one is set).
class PinSetupScreen extends StatefulWidget {
  final bool hasPin;

  const PinSetupScreen({super.key, required this.hasPin});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

enum _Step { confirmCurrent, enterNew, confirmNew }

class _PinSetupScreenState extends State<PinSetupScreen> {
  late _Step _step = widget.hasPin ? _Step.confirmCurrent : _Step.enterNew;
  final _controller = TextEditingController();
  String _firstNewPin = '';
  bool _error = false;
  bool _removing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final entered = _controller.text;
    switch (_step) {
      case _Step.confirmCurrent:
        final ok = await PinVault.verifyPin(entered);
        if (!mounted) return;
        if (!ok) {
          setState(() {
            _error = true;
            _controller.clear();
          });
          return;
        }
        if (_removing) {
          await PinVault.clearPin();
          AppLockController.instance.isLocked.value = false;
          if (mounted) Navigator.of(context).pop(true);
          return;
        }
        setState(() {
          _step = _Step.enterNew;
          _controller.clear();
          _error = false;
        });
      case _Step.enterNew:
        setState(() {
          _firstNewPin = entered;
          _controller.clear();
          _step = _Step.confirmNew;
        });
      case _Step.confirmNew:
        if (entered != _firstNewPin) {
          setState(() {
            _error = true;
            _controller.clear();
            _firstNewPin = '';
            _step = _Step.enterNew;
          });
          return;
        }
        await PinVault.setPin(entered);
        if (mounted) Navigator.of(context).pop(true);
    }
  }

  // TextEditingController.clear() fires onChanged('') too, same as user
  // input — guarding on isNotEmpty stops the programmatic clear right after
  // setting _error = true from immediately undoing it before it ever renders.
  void _onChanged(String value) {
    if (_error && value.isNotEmpty) setState(() => _error = false);
    if (value.length == 4) _submit();
  }

  String get _title {
    if (_removing) return 'Enter your PIN to turn off lock';
    switch (_step) {
      case _Step.confirmCurrent:
        return 'Enter your current PIN';
      case _Step.enterNew:
        return 'Choose a new PIN';
      case _Step.confirmNew:
        return 'Confirm your new PIN';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App lock'),
        actions: [
          if (widget.hasPin && !_removing)
            TextButton(
              onPressed: () => setState(() {
                _removing = true;
                _step = _Step.confirmCurrent;
                _controller.clear();
              }),
              child: const Text('Turn off'),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  obscureText: true,
                  obscuringCharacter: '●',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(letterSpacing: 20),
                  decoration: InputDecoration(
                    counterText: '',
                    errorText: _error ? 'That didn\'t match. Try again.' : null,
                  ),
                  onChanged: _onChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
