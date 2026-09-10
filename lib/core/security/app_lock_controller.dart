import 'package:flutter/widgets.dart';

import 'pin_vault.dart';

/// Tracks whether the app is currently showing the PIN lock screen. A PIN is
/// entirely optional — if none is set, [isLocked] stays false forever and
/// this has no effect on the app.
class AppLockController with WidgetsBindingObserver {
  AppLockController._();

  static final AppLockController instance = AppLockController._();

  final ValueNotifier<bool> isLocked = ValueNotifier(false);
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    isLocked.value = await PinVault.hasPin();
  }

  void unlock() => isLocked.value = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.paused) return;
    PinVault.hasPin().then((hasPin) {
      if (hasPin) isLocked.value = true;
    });
  }
}
