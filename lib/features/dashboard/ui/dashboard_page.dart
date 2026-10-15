import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../tasks/data/models/task.dart';
import '../../tasks/ui/widgets/task_detail_sheet.dart';
import '../providers/dashboard_providers.dart';

final _weekOfFormat = DateFormat('MMMM d');
final _deadlineFormat = DateFormat('EEE, d MMM • HH:mm');

/// Halaman Progress: streak, bar chart mingguan, stat tiles, progress per
/// kategori, lalu daftar task yang mendekati deadline.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(dashboardProvider);

    return statsAsync.when(
      skipLoadingOnRefresh: true,
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.5,
        ),
      ),
      error: (error, _) => AppErrorView(
        error: error,
        onRetry: () => ref.invalidate(dashboardProvider),
      ),
      data: (stats) {
        final now = DateTime.now();
        final monday = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppSurfaces.card,
          onRefresh: () => ref.refresh(dashboardProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 130),
            children: [
              Text(
                'Progress',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Week of ${_weekOfFormat.format(monday)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),

              _StreakHero(
                streak: stats.streak,
                bestStreak: stats.bestStreak,
              ),
              const SizedBox(height: 14),

              _WeeklyBars(
                values: stats.doneByWeekday,
                todayIndex: now.weekday - 1,
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      value: '${stats.doneThisWeek}',
                      label: 'tasks done this week',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      value: '${stats.activeDaysThisWeek}',
                      label: 'active days',
                    ),
                  ),
                ],
              ),

              if (stats.byCategory.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 12),
                  child: Text(
                    'By category',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                for (final cat in stats.byCategory.take(6))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _CategoryProgressRow(cat: cat),
                  ),
              ],

              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                child: Text(
                  'Mendekati deadline (7 hari)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              _DeadlineList(
                overdue: stats.overdue,
                upcoming: stats.upcoming,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Kartu streak dengan gradient navy dan glow hangat.
class _StreakHero extends StatelessWidget {
  const _StreakHero({required this.streak, required this.bestStreak});

  final int streak;
  final int bestStreak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(0.2, -0.5),
          end: Alignment(1.0, 1.0),
          colors: [Color(0xFF052659), Color(0x4D5483B3)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppSurfaces.cardBorderHover),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: IgnorePointer(
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.warm.withValues(alpha: 0.26),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppSurfaces.glassStrong,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  size: 26,
                  color: AppColors.warm,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$streak day streak',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Best: $bestStreak days · Keep it going',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 12,
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

/// Bar chart mingguan "Tasks completed".
class _WeeklyBars extends StatelessWidget {
  const _WeeklyBars({required this.values, required this.todayIndex});

  final List<int> values;
  final int todayIndex;

  static const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxValue =
        values.fold<int>(0, (m, v) => v > m ? v : m).clamp(1, 999);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppSurfaces.glass,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppSurfaces.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tasks completed',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                'This week',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.textSubtle,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 118,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < 7; i++) ...[
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: AppDurations.progressAnimation,
                          curve: Curves.easeOutCubic,
                          width: 26,
                          height: (values[i] / maxValue * 88)
                              .clamp(5, 88)
                              .toDouble(),
                          decoration: BoxDecoration(
                            color: i == todayIndex
                                ? AppColors.primary
                                : AppColors.secondary
                                    .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _dayLetters[i],
                          style:
                              theme.textTheme.labelSmall?.copyWith(
                            color: i == todayIndex
                                ? AppColors.primary
                                : AppColors.textSubtle,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < 6) const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tile angka besar + label.
class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppSurfaces.glass,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppSurfaces.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Baris progress per kategori: dot warna, nama, persen, bar.
class _CategoryProgressRow extends StatelessWidget {
  const _CategoryProgressRow({required this.cat});

  final CategoryProgress cat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorDef = AppCategoryColors.forName(cat.name);

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: colorDef.color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    cat.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${cat.pct}%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: AppSurfaces.glass,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: cat.pct / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorDef.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Task yang lewat atau mendekati deadline. Tap untuk membuka detail.
class _DeadlineList extends StatelessWidget {
  const _DeadlineList({required this.overdue, required this.upcoming});

  final List<Task> overdue;
  final List<Task> upcoming;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (overdue.isEmpty && upcoming.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppSurfaces.glass,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppSurfaces.cardBorder),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.verified_rounded,
              size: 20,
              color: AppColors.success,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Tidak ada task dengan tenggat dekat. Aman! ✨',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget row(Task task, {required bool isOverdue}) {
      final color = isOverdue ? AppColors.error : AppColors.textMuted;
      return GestureDetector(
        onTap: () => showTaskDetailSheet(context, task),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  isOverdue
                      ? Icons.warning_amber_rounded
                      : Icons.schedule_rounded,
                  size: 16,
                  color: color,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                isOverdue
                    ? 'Lewat • ${_deadlineFormat.format(task.dueDate!)}'
                    : _deadlineFormat.format(task.dueDate!),
                style: theme.textTheme.labelSmall?.copyWith(color: color),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppSurfaces.glass,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppSurfaces.cardBorder),
      ),
      child: Column(
        children: [
          for (final task in overdue) row(task, isOverdue: true),
          for (final task in upcoming) row(task, isOverdue: false),
        ],
      ),
    );
  }
}
