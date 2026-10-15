import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Card kaca: background semi-transparan, border tipis, blur dan glow opsional.
class GlassmorphicCard extends StatelessWidget {
  const GlassmorphicCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.enableBlur = false,
    this.enableGlow = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;

  /// Backdrop blur cukup berat, pakai seperlunya.
  final bool enableBlur;

  final bool enableGlow;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.xxl;
    final bg = backgroundColor ?? AppSurfaces.glass;
    final border = borderColor ?? AppSurfaces.cardBorder;

    Widget content = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
        boxShadow: enableGlow ? AppShadows.cardGlow : null,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );

    if (enableBlur) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: content,
        ),
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}
