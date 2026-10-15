import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstraksi penyimpanan token supaya mudah di-mock di unit test.
abstract class TokenStorage {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<void> clear();
}

/// Implementasi produksi berbasis [FlutterSecureStorage]
/// (Keychain di iOS, Keystore/EncryptedSharedPreferences di Android).
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'taskflow_access_token';
  static const _refreshTokenKey = 'taskflow_refresh_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}

/// Implementasi in-memory untuk pengujian.
class InMemoryTokenStorage implements TokenStorage {
  String? accessToken;
  String? refreshToken;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return SecureTokenStorage();
});
