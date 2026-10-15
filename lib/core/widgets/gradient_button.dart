import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Tombol dengan background gradient dan state loading.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.gradient,
    this.isLoading = false,
    this.height = 52,
    this.borderRadius,
    this.width,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Gradient? gradient;
  final bool isLoading;
  final double height;
  final double? borderRadius;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final grad = gradient ?? AppGradients.primary;
    final radius = borderRadius ?? AppRadius.lg;
    final isDisabled = onPressed == null || isLoading;

    return AnimatedContainer(
      duration: AppDurations.microAnimation,
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: isDisabled ? null : grad,
        color: isDisabled ? AppSurfaces.elevated : null,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: isDisabled ? null : AppShadows.buttonGlow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(radius),
          splashColor: Colors.white.withValues(alpha: 0.1),
          highlightColor: Colors.white.withValues(alpha: 0.05),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : DefaultTextStyle(
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: isDisabled
                              ? AppColors.textMuted
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                    child: child,
                  ),
          ),
        ),
      ),
    );
  }
}
