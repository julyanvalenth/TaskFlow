import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/auth_events.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_api.dart';
import '../data/models/user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState(this.status, {this.user});

  final AuthStatus status;
  final User? user;

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  TokenStorage get _storage => ref.read(tokenStorageProvider);
  AuthApi get _api => ref.read(authApiProvider);

  @override
  AuthState build() {
    final sub = ref
        .watch(authEventsProvider)
        .sessionExpired
        .listen((_) => _onSessionExpired());
    ref.onDispose(sub.cancel);

    Future.microtask(_restoreSession);
    return const AuthState(AuthStatus.unknown);
  }

  /// Saat app start, auto-login kalau ada token tersimpan.
  Future<void> _restoreSession() async {
    final token = await _storage.readAccessToken();
    if (token == null) {
      state = const AuthState(AuthStatus.unauthenticated);
      return;
    }
    try {
      final user = await _api.profile();
      state = AuthState(AuthStatus.authenticated, user: user);
    } on ApiException catch (e) {
      if (e.type == ApiErrorType.unauthorized) {
        // Refresh sudah dicoba (dan gagal) oleh interceptor.
        await _storage.clear();
        state = const AuthState(AuthStatus.unauthenticated);
      } else {
        // Server atau jaringan bermasalah tapi token masih ada. Anggap masih
        // login; request berikutnya akan memvalidasi ulang.
        state = const AuthState(AuthStatus.authenticated);
      }
    }
  }

  /// Melempar [ApiException] kalau gagal; form login yang menanganinya.
  Future<void> login({required String email, required String password}) async {
    final tokens = await _api.login(email: email, password: password);
    await _storage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    User? user;
    try {
      user = await _api.profile();
    } on ApiException {
      user = null; // profil bisa dimuat ulang nanti
    }
    state = AuthState(AuthStatus.authenticated, user: user);
  }

  /// Register lalu langsung login.
  Future<void> register({
    required String email,
    required String password,
  }) async {
    await _api.register(email: email, password: password);
    await login(email: email, password: password);
  }

  Future<void> logout() async {
    await _storage.clear();
    state = const AuthState(AuthStatus.unauthenticated);
  }

  void _onSessionExpired() {
    // Token sudah dihapus interceptor.
    state = const AuthState(AuthStatus.unauthenticated);
  }
}
