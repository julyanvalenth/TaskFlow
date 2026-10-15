import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Toggle pill College/Daily. Opsi terpilih diisi gradient.
class ModeSwitch extends StatelessWidget {
  const ModeSwitch({
    super.key,
    required this.modes,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<ModeSwitchItem> modes;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppSurfaces.glass,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppSurfaces.cardBorder),
      ),
      child: Row(
        children: [
          for (int i = 0; i < modes.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: AppDurations.microAnimation,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    gradient: i == selectedIndex
                        ? AppGradients.primarySubtle
                        : null,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: i == selectedIndex
                        ? [
                            BoxShadow(
                              color: AppColors.secondary
                                  .withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: i == selectedIndex
                              ? const Color(0xFF021024)
                              : modes[i].dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        modes[i].label,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: i == selectedIndex
                                  ? const Color(0xFF021024)
                                  : AppColors.textMuted,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ModeSwitchItem {
  const ModeSwitchItem({required this.label, required this.dotColor});
  final String label;
  final Color dotColor;
}
