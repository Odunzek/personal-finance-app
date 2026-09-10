import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'app_lock_controller.dart';
import 'pin_vault.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _auth = LocalAuthentication();
  String _entered = '';
  bool _error = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return;
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock Kinscope',
        biometricOnly: true,
      );
      if (ok) AppLockController.instance.unlock();
    } catch (_) {
      // Fall back to PIN entry silently.
    }
  }

  Future<void> _submit() async {
    setState(() => _checking = true);
    final ok = await PinVault.verifyPin(_entered);
    if (!mounted) return;
    if (ok) {
      AppLockController.instance.unlock();
      return;
    }
    setState(() {
      _error = true;
      _entered = '';
      _checking = false;
    });
  }

  void _press(String key) {
    if (_checking) return;
    setState(() {
      _error = false;
      if (key == '⌫') {
        if (_entered.isNotEmpty) {
          _entered = _entered.substring(0, _entered.length - 1);
        }
      } else if (_entered.length < 6) {
        _entered += key;
      }
    });
    if (_entered.length >= 4 && key != '⌫') {
      _submit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.lock,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text('Enter your PIN', style: Theme.of(context).textTheme.titleMedium),
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
                        _KeypadButton(label: k, onTap: () => _press(k)),
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

class _KeypadButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _KeypadButton({required this.label, required this.onTap});

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
