import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Kartu daily goal: ring progress, jumlah selesai/target, dan badge streak.
class DailyGoalCard extends StatelessWidget {
  const DailyGoalCard({
    super.key,
    required this.done,
    required this.goal,
    required this.streak,
  });

  final int done;
  final int goal;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = goal > 0 ? (done / goal).clamp(0.0, 1.0) : 0.0;
    final goalReached = done >= goal;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppGradients.cardNavy,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppSurfaces.cardBorderHover),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -36,
            right: -24,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6E82FF).withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -46,
            left: 100,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.warm.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CustomPaint(
                  painter: _RingPainter(progress: progress),
                  child: Center(
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Color(0xFF052042),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$done/$goal',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily goal',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      goalReached
                          ? 'Goal reached, nice work!'
                          : '$done of $goal tasks done today',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppSurfaces.glass,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 14,
                      color: AppColors.warm,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$streak',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Conic gradient ring painter.
class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const strokeWidth = 7.0;
    final r = rect.deflate(strokeWidth / 2);

    canvas.drawArc(
      r,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = AppSurfaces.cardBorder,
    );

    if (progress > 0) {
      final sweep = 2 * math.pi * progress;
      final gradient = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + sweep,
        colors: const [Color(0xFF5483B3), Color(0xFFC1E8FF)],
        stops: const [0.0, 1.0],
        transform: const GradientRotation(-math.pi / 2),
      );
      canvas.drawArc(
        r,
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..shader = gradient.createShader(r),
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
