import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/animated_progress_bar.dart';
import '../../../tasks/data/models/task.dart';

/// Bar chart horizontal jumlah task per prioritas. Prioritas itu berurutan
/// (LOW sampai URGENT), jadi warnanya pakai ramp sekuensial; tiap baris tetap
/// diberi label teks dan angka.
class PriorityBarChart extends StatelessWidget {
  const PriorityBarChart({super.key, required this.byPriority});

  final Map<TaskPriority, int> byPriority;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ramp = theme.brightness == Brightness.dark
        ? AppColors.chartRampDark
        : AppColors.chartRampLight;

    final counts = [
      for (final p in TaskPriority.values) (p, byPriority[p] ?? 0),
    ];
    final maxCount =
        counts.fold<int>(0, (m, e) => e.$2 > m ? e.$2 : m).clamp(1, 1 << 31);

    return Column(
      children: [
        for (final (index, entry) in counts.indexed) ...[
          if (index > 0) const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              SizedBox(
                width: 76,
                child: Text(
                  entry.$1.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              Expanded(
                child: AnimatedProgressBar(
                  value: entry.$2 / maxCount,
                  height: 10,
                  gradient: LinearGradient(
                    colors: [
                      ramp[index % ramp.length],
                      ramp[index % ramp.length].withValues(alpha: 0.6),
                    ],
                  ),
                  backgroundColor: AppSurfaces.elevated,
                  showGlow: entry.$2 > 0,
                ),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '${entry.$2}',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
