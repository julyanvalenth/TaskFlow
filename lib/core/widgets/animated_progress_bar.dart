import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Progress bar horizontal dengan gradient fill, rounded ends,
/// dan animasi smooth saat value berubah.
class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.height = 6,
    this.gradient,
    this.backgroundColor,
    this.borderRadius,
    this.duration,
    this.showGlow = false,
  });

  /// Nilai 0.0 sampai 1.0.
  final double value;
  final double height;
  final Gradient? gradient;
  final Color? backgroundColor;
  final double? borderRadius;
  final Duration? duration;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final grad = gradient ?? AppGradients.primary;
    final bg = backgroundColor ?? AppSurfaces.elevated;
    final radius = borderRadius ?? height / 2;
    final dur = duration ?? AppDurations.progressAnimation;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                AnimatedContainer(
                  duration: dur,
                  curve: Curves.easeOutCubic,
                  width: constraints.maxWidth * value.clamp(0.0, 1.0),
                  height: height,
                  decoration: BoxDecoration(
                    gradient: grad,
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: showGlow
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
