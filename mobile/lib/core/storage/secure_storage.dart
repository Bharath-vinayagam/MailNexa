import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// On web, use localStorage directly to avoid Web Crypto OperationError
// On mobile, use flutter_secure_storage with platform-specific encryption
class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserId = 'user_id';
  static const _keyUserEmail = 'user_email';
  static const _keyUserRole = 'user_role';

  // ─── Internal read/write with web fallback ────────────────
  static Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      _webStore[key] = value;
      return;
    }
    await _storage.write(key: key, value: value);
  }

  static Future<String?> _read(String key) async {
    if (kIsWeb) {
      return _webStore[key];
    }
    return _storage.read(key: key);
  }

  static Future<void> _deleteAll() async {
    if (kIsWeb) {
      _webStore.clear();
      return;
    }
    await _storage.deleteAll();
  }

  // Simple in-memory store for web session (cleared on page refresh — acceptable for dev)
  static final Map<String, String> _webStore = {};

  // ─── Public API ───────────────────────────────────────────

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _write(_keyAccessToken, accessToken),
      _write(_keyRefreshToken, refreshToken),
    ]);
  }

  static Future<String?> getAccessToken() => _read(_keyAccessToken);

  static Future<String?> getRefreshToken() => _read(_keyRefreshToken);

  static Future<void> saveUserInfo({
    required String userId,
    required String email,
    required String role,
  }) async {
    await Future.wait([
      _write(_keyUserId, userId),
      _write(_keyUserEmail, email),
      _write(_keyUserRole, role),
    ]);
  }

  static Future<bool> isLoggedIn() async {
    final token = await _read(_keyAccessToken);
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearAll() => _deleteAll();

  static Future<String?> getUserId() => _read(_keyUserId);
  static Future<String?> getUserEmail() => _read(_keyUserEmail);
  static Future<String?> getUserRole() => _read(_keyUserRole);
}
