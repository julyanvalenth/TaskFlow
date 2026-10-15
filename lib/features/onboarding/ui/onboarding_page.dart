import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/lumo_mark.dart';
import '../../settings/providers/settings_providers.dart';

/// Onboarding: logo, tagline, tiga value prop, dan CTA. Hanya muncul sekali
/// sebelum login pertama.
class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  Future<void> _continueTo(
    BuildContext context,
    WidgetRef ref,
    String route,
  ) async {
    await ref.read(settingsProvider.notifier).markOnboardingSeen();
    if (context.mounted) context.go(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppSurfaces.background,
      body: Stack(
        children: [
          const _Glow(top: -120, right: -100, size: 340,
              color: Color(0x8C5483B3)),
          const _Glow(top: 180, left: -140, size: 320,
              color: Color(0x426076FF)),
          const _Glow(bottom: -90, right: -70, size: 280,
              color: Color(0x4D7DA0CA)),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 72, 28, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LumoMarkTile(size: 72),
                  const SizedBox(height: 28),

                  Text(
                    'TaskFlow',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 42,
                      letterSpacing: -1,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 17,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          const TextSpan(text: 'The calm way to get '),
                          TextSpan(
                            text: 'coursework done.',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              foreground: Paint()
                                ..shader = const LinearGradient(
                                  colors: [
                                    Color(0xFF7DA0CA),
                                    Color(0xFFC1E8FF),
                                  ],
                                ).createShader(
                                  const Rect.fromLTWH(0, 0, 220, 24),
                                ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 44),

                  const _FeatureRow(
                    icon: Icons.calendar_month_rounded,
                    text: 'Every class and deadline in one timeline',
                  ),
                  const SizedBox(height: 18),
                  const _FeatureRow(
                    icon: Icons.local_fire_department_rounded,
                    text: 'Daily goals that build a streak',
                  ),
                  const SizedBox(height: 18),
                  const _FeatureRow(
                    icon: Icons.checklist_rounded,
                    text: 'Big assignments, broken into small steps',
                  ),

                  const Spacer(),

                  GestureDetector(
                    onTap: () => _continueTo(context, ref, '/register'),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: AppShadows.buttonGlow,
                      ),
                      child: Center(
                        child: Text(
                          'Get Started',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF021024),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: GestureDetector(
                      onTap: () => _continueTo(context, ref, '/login'),
                      child: Text(
                        'I already have an account',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppSurfaces.glass,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppSurfaces.cardBorder),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
          ),
        ),
      ],
    );
  }
}

/// Lingkaran glow radial dekoratif.
class _Glow extends StatelessWidget {
  const _Glow({
    required this.size,
    required this.color,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  final double size;
  final Color color;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }
}
