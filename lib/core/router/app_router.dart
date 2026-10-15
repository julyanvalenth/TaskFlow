import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/ui/login_page.dart';
import '../../features/auth/ui/register_page.dart';
import '../../features/dashboard/ui/dashboard_page.dart';
import '../../features/onboarding/ui/onboarding_page.dart';
import '../../features/profile/ui/profile_page.dart';
import '../../features/schedule/ui/schedule_page.dart';
import '../../features/tasks/ui/task_form_page.dart';
import '../../features/tasks/ui/task_list_page.dart';
import '../theme/app_tokens.dart';
import '../widgets/lumo_mark.dart';
import 'home_shell.dart';

/// Dipanggil sekali dari [_TaskFlowAppState.initState].
///
/// [authNotifier] di-update oleh [_TaskFlowAppState.build] tiap auth berubah.
/// GoRouter mendengarkannya lewat [refreshListenable] dan mengevaluasi ulang
/// [_redirect] tanpa membuat router baru, jadi tidak ada layar hitam.
///
/// [isOnboardingSeen] dibaca saat redirect; user baru diarahkan ke
/// onboarding sebelum login.
GoRouter buildGoRouter(
  ValueNotifier<AuthState> authNotifier, {
  required bool Function() isOnboardingSeen,
}) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authNotifier,
    redirect: (context, state) =>
        _redirect(authNotifier.value, state, isOnboardingSeen()),
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (c, s) => const _SplashScreen(),
      ),

      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (c, s) => const OnboardingPage(),
      ),

      GoRoute(
        path: '/login',
        name: 'login',
        builder: (c, s) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (c, s) => const RegisterPage(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => HomeShell(
          navigationShell: navigationShell,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (c, s) => const TaskListPage(),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: 'newTask',
                    builder: (c, s) => const TaskFormPage(),
                  ),
                ],
              ),
              GoRoute(
                path: '/tasks/:id/edit',
                name: 'editTask',
                builder: (c, s) => TaskFormPage(
                  taskId: s.pathParameters['id'],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/schedule',
                name: 'schedule',
                builder: (c, s) => const SchedulePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                name: 'dashboard',
                builder: (c, s) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (c, s) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Redirect logic berdasarkan auth status + flag onboarding.
String? _redirect(AuthState auth, GoRouterState state, bool onboardSeen) {
  final path = state.uri.path;
  final isAuth = path.startsWith('/login') || path.startsWith('/register');
  final isSplash = path == '/splash';
  final isOnboard = path == '/onboarding';

  switch (auth.status) {
    case AuthStatus.unknown:
      // Token masih dimuat, tetap di splash.
      return isSplash ? null : '/splash';

    case AuthStatus.unauthenticated:
      // Belum login. User baru lihat onboarding dulu.
      if (!onboardSeen) return isOnboard ? null : '/onboarding';
      if (isAuth || isOnboard) return null;
      return '/login';

    case AuthStatus.authenticated:
      // Sudah login, keluar dari splash/login/register/onboarding.
      if (isSplash || isAuth || isOnboard) return '/home';
      return null;
  }
}

/// Layar sementara saat AuthStatus.unknown.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppSurfaces.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LumoMarkTile(size: 88),
            SizedBox(height: 28),
            CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
