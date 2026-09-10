import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores a salted hash of the app-lock PIN, never the PIN itself. This gates
/// the local UI only — Supabase auth + RLS remain the real access boundary,
/// so a simple salted SHA-256 (rather than a slower KDF) is an appropriate
/// match for the threat model of "someone picks up my unlocked phone."
class PinVault {
  PinVault._();

  static const _storage = FlutterSecureStorage();
  static const _saltKey = 'app_lock_salt';
  static const _hashKey = 'app_lock_hash';

  static Future<bool> hasPin() async {
    return await _storage.read(key: _hashKey) != null;
  }

  static Future<void> setPin(String pin) async {
    final salt = _randomSalt();
    await _storage.write(key: _saltKey, value: salt);
    await _storage.write(key: _hashKey, value: _hash(pin, salt));
  }

  static Future<bool> verifyPin(String pin) async {
    final salt = await _storage.read(key: _saltKey);
    final storedHash = await _storage.read(key: _hashKey);
    if (salt == null || storedHash == null) return false;
    return _hash(pin, salt) == storedHash;
  }

  static Future<void> clearPin() async {
    await _storage.delete(key: _saltKey);
    await _storage.delete(key: _hashKey);
  }

  static String _randomSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String _hash(String pin, String salt) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }
}
