import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Checkbox kotak rounded, terisi ice blue saat dicentang.
class LumoCheckbox extends StatelessWidget {
  const LumoCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 22,
    this.borderRadius = 8,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: AppDurations.microAnimation,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: value ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          border: value
              ? null
              : Border.all(
                  color: AppColors.textSubtle.withValues(alpha: 0.5),
                  width: 1.5,
                ),
        ),
        child: value
            ? Icon(
                Icons.check_rounded,
                size: size * 0.6,
                color: const Color(0xFF021024),
              )
            : null,
      ),
    );
  }
}
