import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Interceptor JWT:
///
/// 1. Menambahkan `Authorization: Bearer <accessToken>` ke request non-publik.
/// 2. Saat dapat 401, memanggil `POST /auth/refresh`, menyimpan token baru,
///    lalu me-retry request asli satu kali.
/// 3. Kalau refresh gagal, token dihapus dan [onSessionExpired] dipanggil
///    (AuthController lalu logout dan redirect ke login).
///
/// Pakai [QueuedInterceptor] supaya beberapa 401 yang datang bersamaan
/// diproses bergiliran dan tidak memicu refresh ganda.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required Dio refreshDio,
    required TokenStorage storage,
    this.onSessionExpired,
  })  : _refreshDio = refreshDio,
        _storage = storage;

  /// Dio tanpa interceptor ini, untuk memanggil /auth/refresh dan me-retry
  /// request asli. Retry jangan lewat Dio utama: onError [QueuedInterceptor]
  /// diproses bergiliran, jadi error dari retry yang masuk lagi ke sini akan
  /// saling menunggu (deadlock).
  final Dio _refreshDio;

  final TokenStorage _storage;
  final void Function()? onSessionExpired;

  static const _retriedKey = '__auth_retried__';
  static const _publicPaths = {
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
  };

  bool _isPublic(RequestOptions options) =>
      _publicPaths.any((p) => options.path.endsWith(p));

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublic(options)) {
      final token = await _storage.readAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;

    if (!isUnauthorized ||
        _isPublic(options) ||
        options.extra[_retriedKey] == true) {
      handler.next(err);
      return;
    }

    // Request lain mungkin sudah refresh duluan selama kita antre. Kalau token
    // tersimpan sudah beda dari yang dipakai request ini, langsung retry saja.
    final storedAccess = await _storage.readAccessToken();
    final usedAuth = options.headers['Authorization'] as String?;
    if (storedAccess != null && usedAuth != 'Bearer $storedAccess') {
      await _retry(options, storedAccess, handler, err);
      return;
    }

    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null) {
      await _expireSession();
      handler.next(err);
      return;
    }

    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data!;
      final newAccess = data['accessToken'] as String;
      final newRefresh = data['refreshToken'] as String;
      await _storage.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );
      await _retry(options, newAccess, handler, err);
    } on DioException {
      await _expireSession();
      handler.next(err);
    }
  }

  Future<void> _retry(
    RequestOptions options,
    String accessToken,
    ErrorInterceptorHandler handler,
    DioException originalError,
  ) async {
    options.headers['Authorization'] = 'Bearer $accessToken';
    options.extra[_retriedKey] = true;
    try {
      final response = await _refreshDio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<void> _expireSession() async {
    await _storage.clear();
    onSessionExpired?.call();
  }
}
