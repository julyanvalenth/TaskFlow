import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/lumo_mark.dart';
import '../providers/auth_providers.dart';

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Email wajib diisi';
  if (!_emailPattern.hasMatch(v)) return 'Format email tidak valid';
  return null;
}

String? validatePassword(String? value) {
  final v = value ?? '';
  if (v.isEmpty) return 'Password wajib diisi';
  if (v.length < 8) return 'Password minimal 8 karakter';
  return null;
}

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      // Redirect ke /tasks ditangani router berdasarkan auth state.
    } on ApiException catch (e) {
      setState(() {
        _error = e.statusCode == 401
            ? 'Email atau password salah.'
            : e.displayMessage;
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppSurfaces.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppGradients.backgroundGlow,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: LumoMarkTile(size: 72)),
                        const SizedBox(height: AppSpacing.lg),

                        Text(
                          'TaskFlow',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Masuk untuk mengelola task Anda',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),

                        if (_error != null) ...[
                          InlineErrorBanner(message: _error!),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.mail_outline_rounded),
                          ),
                          validator: validateEmail,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          autofillHints: const [AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon:
                                const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: validatePassword,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        GradientButton(
                          onPressed: _submitting ? null : _submit,
                          isLoading: _submitting,
                          child: const Text('Masuk'),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        TextButton(
                          onPressed: _submitting
                              ? null
                              : () => context.go('/register'),
                          child: Text(
                            'Belum punya akun? Daftar',
                            style: TextStyle(
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
