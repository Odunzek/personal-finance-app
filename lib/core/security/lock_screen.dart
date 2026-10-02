import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _error = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    var unlocked = false;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (canCheck) {
        unlocked = await _auth.authenticate(
          localizedReason: 'Unlock Kinscope',
          biometricOnly: true,
        );
      }
    } catch (_) {
      // Fall back to PIN entry silently.
    }
    if (!mounted) return;
    if (unlocked) {
      AppLockController.instance.unlock();
      return;
    }
    // Only summon the keyboard once the biometric prompt is out of the
    // way — an autofocus fired while that system dialog held window focus
    // gets silently swallowed, leaving a focused field with no keyboard
    // and no reliable way to bring one up. The short delay lets window
    // focus actually return to the app first; a request made during the
    // dialog's dismissal animation is dropped the same way.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    _focusNode.requestFocus();
  }

  Future<void> _submit() async {
    if (_checking) return;
    setState(() => _checking = true);
    final ok = await PinVault.verifyPin(_controller.text);
    if (!mounted) return;
    if (ok) {
      AppLockController.instance.unlock();
      return;
    }
    setState(() {
      _error = true;
      _controller.clear();
      _checking = false;
    });
  }

  // TextEditingController.clear() fires onChanged('') too, same as user
  // input — guarding on isNotEmpty stops that programmatic clear (right
  // after setting _error = true above) from immediately undoing it before
  // the message ever renders.
  void _onChanged(String value) {
    if (_error && value.isNotEmpty) setState(() => _error = false);
    if (value.length == 4) _submit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.lock,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Enter your PIN',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
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
                    errorText: _error ? 'That didn\'t match.' : null,
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
