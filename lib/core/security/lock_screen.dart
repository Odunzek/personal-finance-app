import 'dart:async';

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
  static const _maxAttemptsBeforeCooldown = 5;
  static const _cooldown = Duration(seconds: 30);

  final _auth = LocalAuthentication();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _error = false;
  bool _checking = false;
  int _failedAttempts = 0;
  DateTime? _cooldownUntil;
  Timer? _cooldownTicker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  @override
  void dispose() {
    _cooldownTicker?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _coolingDown =>
      _cooldownUntil != null && DateTime.now().isBefore(_cooldownUntil!);

  int get _cooldownSecondsLeft => _coolingDown
      ? _cooldownUntil!.difference(DateTime.now()).inSeconds + 1
      : 0;

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

  void _startCooldown() {
    _cooldownUntil = DateTime.now().add(_cooldown);
    _failedAttempts = 0;
    _cooldownTicker?.cancel();
    _cooldownTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!_coolingDown) {
        timer.cancel();
        setState(() => _cooldownUntil = null);
        _focusNode.requestFocus();
      } else {
        setState(() {});
      }
    });
  }

  Future<void> _submit() async {
    if (_checking || _coolingDown) return;
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
      _failedAttempts++;
      if (_failedAttempts >= _maxAttemptsBeforeCooldown) {
        _startCooldown();
      }
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
    final coolingDown = _coolingDown;
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
                  enabled: !coolingDown,
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
                    errorText: coolingDown
                        ? 'Too many attempts — wait '
                              '$_cooldownSecondsLeft s.'
                        : (_error ? 'That didn\'t match.' : null),
                  ),
                  onChanged: _onChanged,
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: coolingDown ? null : _tryBiometric,
                  icon: const Icon(LucideIcons.fingerprint, size: 18),
                  label: const Text('Use fingerprint'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
