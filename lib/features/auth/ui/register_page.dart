import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/lumo_mark.dart';
import '../providers/auth_providers.dart';
import 'login_page.dart' show validateEmail, validatePassword;

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
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
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      // Setelah register + auto-login, router redirect ke /tasks.
    } on ApiException catch (e) {
      setState(() {
        _error = e.type == ApiErrorType.conflict
            ? 'Email sudah terdaftar. Silakan masuk.'
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppSurfaces.card,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppSurfaces.cardBorder),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 20),
          ),
          onPressed: () => context.go('/login'),
        ),
      ),
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
                        const Center(child: LumoMarkTile(size: 64)),
                        const SizedBox(height: AppSpacing.lg),

                        Text(
                          'Buat Akun',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Daftar dengan email dan password',
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
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            helperText: 'Minimal 8 karakter',
                            helperStyle: TextStyle(
                              color: AppColors.textSubtle,
                            ),
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
                        const SizedBox(height: AppSpacing.md),

                        TextFormField(
                          controller: _confirmController,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Ulangi password',
                            prefixIcon: Icon(Icons.lock_reset_rounded),
                          ),
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Password tidak sama';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        GradientButton(
                          onPressed: _submitting ? null : _submit,
                          isLoading: _submitting,
                          child: const Text('Daftar'),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        TextButton(
                          onPressed: _submitting
                              ? null
                              : () => context.go('/login'),
                          child: Text(
                            'Sudah punya akun? Masuk',
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
