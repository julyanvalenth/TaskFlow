import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_providers.dart';
import 'features/settings/providers/settings_providers.dart';

/// Root widget. [GoRouter] dibuat sekali di [initState] supaya tidak ikut
/// dibuat ulang saat auth berubah. Perubahan auth diteruskan lewat
/// [_authNotifier] ke [GoRouter.refreshListenable], jadi router cukup
/// mengevaluasi ulang redirect.
class TaskFlowApp extends ConsumerStatefulWidget {
  const TaskFlowApp({super.key});

  @override
  ConsumerState<TaskFlowApp> createState() => _TaskFlowAppState();
}

class _TaskFlowAppState extends ConsumerState<TaskFlowApp> {
  late final ValueNotifier<AuthState> _authNotifier;

  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    final initialAuth = ref.read(authControllerProvider);
    _authNotifier = ValueNotifier<AuthState>(initialAuth);

    _router = buildGoRouter(
      _authNotifier,
      isOnboardingSeen: () => ref.read(settingsProvider).onboardingSeen,
    );
  }

  @override
  void dispose() {
    _authNotifier.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    // Post-frame agar tidak update ValueNotifier di tengah build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_authNotifier.value.status != auth.status) {
        _authNotifier.value = auth;
      }
    });

    // Desain Lumo cuma dark. Light theme masih ada sebagai fallback, tapi
    // tidak bisa dipilih user.
    return MaterialApp.router(
      title: 'TaskFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: _router,
    );
  }
}
