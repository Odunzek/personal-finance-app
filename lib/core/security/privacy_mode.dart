import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Whether money amounts are masked on screen. Every figure in the app
/// renders through MoneyText, so this one flag hides all of them at once —
/// hiding only the headline would leave the account balances underneath it
/// giving the same thing away.
final privacyModeNotifier = ValueNotifier<bool>(false);

class PrivacyMode {
  PrivacyMode._();

  static const _storage = FlutterSecureStorage();
  static const _key = 'amounts_hidden';

  /// What a masked amount reads as. Fixed width on purpose: a mask that grew
  /// with the number would still leak its magnitude.
  static const mask = '\$••••';

  /// Read once at startup so the choice survives a restart. Defaults to
  /// visible if storage throws — failing closed would hide every number with
  /// no obvious way back.
  static Future<void> init() async {
    try {
      privacyModeNotifier.value = await _storage.read(key: _key) != null;
    } catch (_) {
      privacyModeNotifier.value = false;
    }
  }

  static Future<void> setHidden(bool hidden) async {
    privacyModeNotifier.value = hidden;
    try {
      if (hidden) {
        await _storage.write(key: _key, value: '1');
      } else {
        await _storage.delete(key: _key);
      }
    } catch (_) {
      // The toggle still applies for this session.
    }
  }

  static Future<void> toggle() => setHidden(!privacyModeNotifier.value);
}
