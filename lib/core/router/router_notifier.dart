import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_providers.dart';

/// [ChangeNotifier] untuk [GoRouter.refreshListenable]. Memanggil
/// [notifyListeners] tiap status di [authControllerProvider] berubah, supaya
/// GoRouter mengevaluasi ulang [redirect] tanpa membuat router baru.
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authControllerProvider,
      (previous, next) {
        if (previous?.status != next.status) {
          notifyListeners();
        }
      },
    );
  }

  final Ref _ref;

  AuthState get _auth => _ref.read(authControllerProvider);

  /// Dipanggil GoRouter setiap kali notifyListeners().
  String? redirect(BuildContext context, GoRouterState state) {
    final path = state.uri.path;
    final isAuth =
        path.startsWith('/login') || path.startsWith('/register');
    final isSplash = path == '/splash';

    switch (_auth.status) {
      case AuthStatus.unknown:
        // Token masih dimuat, tetap di splash.
        return isSplash ? null : '/splash';

      case AuthStatus.unauthenticated:
        if (isAuth) return null;
        return '/login';

      case AuthStatus.authenticated:
        // Sudah login, keluar dari splash/login/register.
        if (isSplash || isAuth) return '/home';
        return null;
    }
  }
}
