import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  String _entered = '';
  String _firstNewPin = '';
  bool _error = false;
  bool _removing = false;

  Future<void> _submit() async {
    switch (_step) {
      case _Step.confirmCurrent:
        final ok = await PinVault.verifyPin(_entered);
        if (!mounted) return;
        if (!ok) {
          setState(() {
            _error = true;
            _entered = '';
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
          _entered = '';
          _error = false;
        });
      case _Step.enterNew:
        setState(() {
          _firstNewPin = _entered;
          _entered = '';
          _step = _Step.confirmNew;
        });
      case _Step.confirmNew:
        if (_entered != _firstNewPin) {
          setState(() {
            _error = true;
            _entered = '';
            _firstNewPin = '';
            _step = _Step.enterNew;
          });
          return;
        }
        await PinVault.setPin(_entered);
        if (mounted) Navigator.of(context).pop(true);
    }
  }

  void _press(String key) {
    setState(() {
      _error = false;
      if (key == '⌫') {
        if (_entered.isNotEmpty) _entered = _entered.substring(0, _entered.length - 1);
        return;
      }
      if (_entered.length < 6) _entered += key;
    });
    if (_entered.length >= 4 && key != '⌫') _submit();
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
                _entered = '';
              }),
              child: const Text('Turn off'),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_title, style: Theme.of(context).textTheme.titleMedium),
                if (_error) ...[
                  const SizedBox(height: 8),
                  Text(
                    'That didn\'t match. Try again.',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) {
                    final filled = i < _entered.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _error
                            ? Theme.of(context).colorScheme.error
                            : filled
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    for (final k in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'])
                      if (k.isEmpty)
                        const SizedBox.shrink()
                      else
                        _PadButton(label: k, onTap: () => _press(k)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PadButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PadButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Center(
          child: label == '⌫'
              ? const Icon(LucideIcons.delete)
              : Text(label, style: Theme.of(context).textTheme.titleLarge),
        ),
      ),
    );
  }
}
